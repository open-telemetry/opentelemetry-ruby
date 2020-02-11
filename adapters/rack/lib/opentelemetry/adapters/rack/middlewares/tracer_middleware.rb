# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../util/queue_time'

module OpenTelemetry
  module Adapters
    module Rack
      module Middlewares
        # TracerMiddleware propagates context and instruments Rack requests
        # by way of its middleware system
        #
        # Notable implementation differences from dd-trace-rb:
        # * missing: 'span.resource', which is set to span.name
        # * missing: config[:distributed_tracing]
        # * missing: span.set_error() -- spec level change
        class TracerMiddleware # rubocop:disable Metrics/ClassLength
          class << self
            def allowed_rack_request_headers
              @allowed_rack_request_headers ||= {}.tap do |result|
                allowed_request_header_names.each do |header|
                  result["HTTP_#{header.to_s.upcase.gsub(/[-\s]/, '_')}"] = build_attribute_name('http.request.headers.', header)
                end
              end
            end

            def allowed_request_header_names
              @allowed_request_header_names ||= Array(config[:allowed_request_headers])
            end

            def allowed_response_headers
              @allowed_response_headers ||= {}.tap do |result|
                allowed_response_header_names.each do |header|
                  result[header] = build_attribute_name('http.response.headers.', header)
                  result[header.to_s.upcase] = build_attribute_name('http.response.headers.', header)
                end
              end
            end

            def allowed_response_header_names
              @allowed_response_header_names ||= Array(config[:allowed_response_headers])
            end

            def build_attribute_name(prefix, suffix)
              prefix + suffix.to_s.downcase.gsub(/[-\s]/, '_')
            end

            def config
              Rack::Adapter.instance.config
            end

            private

            def clear_cached_config
              @allowed_rack_request_headers = nil
              @allowed_request_header_names = nil

              @allowed_response_headers = nil
              @allowed_response_header_names = nil
            end
          end

          EMPTY_HASH = {}.freeze

          def initialize(app)
            @app = app
          end

          def call(env) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            original_env = env.dup

            parent_context = OpenTelemetry.tracer_factory.http_text_format.extract(env)

            ### frontend span
            # NOTE: get_request_start may return nil
            request_start_time = OpenTelemetry::Adapters::Rack::Util::QueueTime.get_request_start(env)
            frontend_span = tracer.start_span('http_server.queue', # NOTE: span kind of 'proxy' is not defined
                                              with_parent_context: parent_context,
                                              # NOTE: initialize with as many attributes as possible:
                                              attributes: {
                                                'component' => 'http',
                                                'service' => config[:web_service_name],
                                                # NOTE: dd-trace-rb differences:
                                                # 'trace.span_type' => (http) 'proxy'
                                                'start_time' => request_start_time
                                              })

            record_frontend_span = config[:record_frontend_span] && !request_start_time.nil?
            frontend_span = if record_frontend_span
                              tracer.start_span('http_server.queue', # NOTE: span kind of 'proxy' is not defined
                                                with_parent_context: parent_context,
                                                # NOTE: initialize with as many attributes as possible:
                                                attributes: {
                                                  'component' => 'http',
                                                  'service' => config[:web_service_name],
                                                  # NOTE: dd-trace-rb differences:
                                                  # 'trace.span_type' => (http) 'proxy'
                                                  'start_time' => request_start_time
                                                })
                            end

            # http://www.rubydoc.info/github/rack/rack/file/SPEC
            # The source of truth in Rack is the PATH_INFO key that holds the
            # URL for the current request; but some frameworks may override that
            # value, especially during exception handling.
            #
            # Because of this, we prefer to use REQUEST_URI, if available, which is the
            # relative path + query string, and doesn't mutate.
            #
            # REQUEST_URI is only available depending on what web server is running though.
            # So when its not available, we want the original, unmutated PATH_INFO, which
            # is just the relative path without query strings.
            request_span_name = create_request_span_name(env['REQUEST_URI'] || original_env['PATH_INFO'])

            rack_request = ::Rack::Request.new(env)
            # Sets as many attributes as are available before control
            # is handed off to next middleware.
            request_span = tracer.start_span(request_span_name,
                                             with_parent_context: parent_context,
                                             # NOTE: try to set as many attributes via 'attributes' argument
                                             #       instead of via span.set_attribute
                                             attributes: request_span_attributes(env: env,
                                                                                 full_http_request_url: full_http_request_url(rack_request),
                                                                                 full_path: full_path(rack_request),
                                                                                 base_url: base_url(rack_request)),
                                             kind: :server)

            @app.call(env).tap do |status, headers, response|
              set_attributes_after_request(request_span, status, headers, response)
            end
          rescue StandardError => e
            record_and_reraise_error(e, request_span: request_span)
          ensure
            request_span.finish
            frontend_span&.finish if record_frontend_span
          end

          private

          def tracer
            OpenTelemetry::Adapters::Rack::Adapter.instance.tracer
          end

          ### request_span

          # Per https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#http-server-semantic-conventions
          #
          # One of the following sets is required, in descending preference:
          # * http.scheme, http.host, http.target
          # * http.scheme, http.server_name, net.host.port, http.target
          # * http.scheme, net.host.name, net.host.port, http.target
          # * http.url
          def request_span_attributes(env:, full_http_request_url:, full_path:, base_url:)
            {
              'component' => 'http',
              'http.method' => env['REQUEST_METHOD'],
              'http.url' => full_http_request_url,
              'http.host' => env['HOST'],
              'http.scheme' => env['rack.url_scheme'],
              'http.target' => full_path,
              'http.base_url' => base_url # NOTE: 'http.base_url' isn't officially defined
            }.merge(allowed_request_headers(env))
          end

          def full_http_request_url(rack_request)
            rack_request.url
          end

          # https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#name
          #
          # recommendation: span.name(s) should be low-cardinality (e.g.,
          # strip off query param value, keep param name)
          #
          # see http://github.com/open-telemetry/opentelemetry-specification/pull/416/files
          def create_request_span_name(request_uri_or_path_info)
            # NOTE: dd-trace-rb has implemented 'quantization' (which lowers url cardinality)
            #       see Datadog::Quantization::HTTP.url

            if (implementation = config[:url_quantization])
              implementation.call(request_uri_or_path_info)
            else
              request_uri_or_path_info
            end
          end

          def base_url(rack_request)
            if rack_request.respond_to?(:base_url)
              rack_request.base_url
            else
              # Compatibility for older Rack versions
              rack_request.url.chomp(rack_request.fullpath)
            end
          end

          # e.g., "/webshop/articles/4?s=1"
          def full_path(rack_request)
            rack_request.fullpath
          end

          # catch exceptions that may be raised in the middleware chain
          # Note: if a middleware catches an Exception without re raising,
          # the Exception cannot be recorded here.
          def record_and_reraise_error(error, request_span:)
            request_span.status = OpenTelemetry::Trace::Status.new(
              OpenTelemetry::Trace::Status::INTERNAL_ERROR,
              description: error.to_s
            )

            # TODO: implement span.set_error? (this is a specification-level issue):
            # request_span.set_error(error) unless request_span.nil?
            #
            raise error
          end

          def set_attributes_after_request(span, status, headers, _response)
            span.status = OpenTelemetry::Trace::Status.http_to_status(status)
            span.set_attribute('http.status_code', status)

            # NOTE: if data is available, it would be good to do this:
            # set_attribute('http.route', ...
            # e.g., "/users/:userID?
            span.set_attribute('http.status_text', ::Rack::Utils::HTTP_STATUS_CODES[status])

            allowed_response_headers(headers).each { |k, v| span.set_attribute(k, v) }
          end

          # @return Hash
          def allowed_request_headers(env)
            {}.tap do |result|
              self.class.allowed_rack_request_headers.each do |key, value|
                result[value] = env[key] if env.key?(key)
              end
            end
          end

          # @return Hash
          def allowed_response_headers(headers)
            return EMPTY_HASH if headers.nil?

            {}.tap do |result|
              self.class.allowed_response_headers.each do |key, value|
                if headers.key?(key)
                  result[value] = headers[key]
                else
                  # do case-insensitive match:
                  headers.each do |k, v|
                    if k.upcase == key
                      result[value] = v
                      break
                    end
                  end
                end
              end
            end
          end

          def config
            Rack::Adapter.instance.config
          end
        end
      end
    end
  end
end
