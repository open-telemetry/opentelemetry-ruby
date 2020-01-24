# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../util/queue_time'

module OpenTelemetry
  module Adapters
    module Rack
      module Middlewares
        # Notable implementation differences from dd-trace-rb:
        # * missing: 'span.resource', which is set to span.name
        # * missing: config[:distributed_tracing]
        # * missing: span.set_error() -- spec level change
        class TracerMiddleware
          class << self
            def allowed_rack_request_headers
              @allowed_rack_request_header_names ||= allowed_request_header_names.map do |header|
                {
                  header: header,
                  rack_header: "HTTP_#{header.to_s.upcase.gsub(/[-\s]/, '_')}"
                }
              end
            end

            def allowed_request_header_names
              @allowed_request_header_names ||= Array(config[:allowed_request_headers])
            end

            def config
              Rack::Adapter.instance.config
            end

            private

            def clear_cached_config
              @allowed_request_header_names = nil
              @allowed_rack_request_header_names = nil
            end
          end

          def initialize(app)
            @app = app
          end

          def call(env)
            # since middleware may only be initialized once (memoized),
            # but we want to be sure to have a clean slate on each request:
            dup._call env
          end

          def _call(env)
            @env = env
            @original_env = env.dup

            frontend_span.start if record_frontend_span?
            extract_parent_context

            start_request_span
            app.call(env).tap do |status, headers, response|
              set_attributes_after_request(request_span, status, headers, response)
            end
          rescue Exception => e
            record_and_reraise_error(e)
          ensure
            request_span.finish
            frontend_span.finish if record_frontend_span?
          end

          private

          attr_reader :app,
                      :env,
                      :original_env,
                      :parent_context,
                      :request_span

          ### parent context

          def extract_parent_context
            @parent_context ||= OpenTelemetry.tracer_factory.http_text_format.extract(env)
          end

          def tracer
            OpenTelemetry::Adapters::Rack::Adapter.instance.tracer
          end

          ### request_span

          # Sets as many attributes as are available before control
          # is handed off to next middleware.
          def start_request_span
            @request_span ||= tracer.start_span(request_span_name,
                                                with_parent_context: parent_context,
                                                # NOTE: try to set as many attributes via 'attributes' argument
                                                #       instead of via span.set_attribute
                                                attributes: request_span_attributes,
                                                kind: :server)
          end

          # Per https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#http-server-semantic-conventions
          #
          # One of the following sets is required, in descending preference:
          # * http.scheme, http.host, http.target
          # * http.scheme, http.server_name, net.host.port, http.target
          # * http.scheme, net.host.name, net.host.port, http.target
          # * http.url
          def request_span_attributes
            {
              'component' => 'http',
              'http.method' => env['REQUEST_METHOD'],
              'http.url' => full_http_request_url,
              'http.host' => env['HOST'],
              'http.scheme' => env['rack.url_scheme'],
              'http.target' => full_path,
              'http.base_url' => base_url # NOTE: 'http.base_url' isn't officially defined
            }.merge(allowed_request_headers)
          end

          def full_http_request_url
            rack_request.url
          end

          # https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#name
          #
          # recommendation: span.name(s) should be low-cardinality (e.g.,
          # strip off query param value, keep param name)
          #
          # see http://github.com/open-telemetry/opentelemetry-specification/pull/416/files
          def request_span_name
            # NOTE: dd-trace-rb has implemented 'quantization' (which lowers url cardinality)
            #       see Datadog::Quantization::HTTP.url

            if (implementation = config[:url_quantization])
              implementation.call(request_uri_or_path_info)
            else
              request_uri_or_path_info
            end
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
          def request_uri_or_path_info
            env['REQUEST_URI'] || original_env['PATH_INFO']
          end

          def base_url
            if rack_request.respond_to?(:base_url)
              rack_request.base_url
            else
              # Compatibility for older Rack versions
              rack_request.url.chomp(rack_request.fullpath)
            end
          end

          # e.g., "/webshop/articles/4?s=1"
          def full_path
            rack_request.fullpath
          end

          def rack_request
            @rack_request ||= ::Rack::Request.new(env)
          end

          # catch exceptions that may be raised in the middleware chain
          # Note: if a middleware catches an Exception without re raising,
          # the Exception cannot be recorded here.
          def record_and_reraise_error(error)
            request_span.status = OpenTelemetry::Trace::Status.new(
              OpenTelemetry::Trace::Status::INTERNAL_ERROR,
              description: error.to_s)

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
          def allowed_request_headers
            {}.tap do |result|
              self.class.allowed_rack_request_headers.each do |hash|
                if env.key?(hash[:rack_header])
                  result[build_attribute_name('http.request.headers.', hash[:header])] = env[hash[:rack_header]]
                end
              end
            end
          end

          # @return Hash
          def allowed_response_headers(headers)
            return {} if headers.nil?

            {}.tap do |result|
              Array(allowed_response_header_names).each do |header|
                new_key_name = build_attribute_name('http.response.headers.', header)
                if headers.key?(header)
                  result[new_key_name] = headers[header]
                else
                  # Try a case-insensitive lookup
                  uppercased_header = header.to_s.upcase
                  matching_header = headers.keys.find { |h| h.upcase == uppercased_header }
                  if matching_header
                    result[new_key_name] = headers[matching_header]
                  end
                end
              end
            end
          end

          def allowed_response_header_names
            Array(config[:allowed_response_headers])
          end

          def build_attribute_name(prefix, suffix)
            prefix + suffix.to_s.downcase.gsub(/[-\s]/, '_')
          end

          def config
            Rack::Adapter.instance.config
          end

          ### frontend span

          def record_frontend_span?
            Rack::Adapter.instance.config[:record_frontend_span] &&
              frontend_span.recordable?
          end

          def frontend_span
            @frontend_span ||= FrontendSpan.new(env: env,
                                                tracer: tracer,
                                                parent_context: parent_context,
                                                web_service_name: config[:web_service_name])
          end

          class FrontendSpan
            def initialize(env:, tracer:, parent_context:, web_service_name:)
              @env = env
              @tracer = tracer
              @parent_context = parent_context

              # NOTE: get_request_start may return nil
              @request_start_time = OpenTelemetry::Adapters::Rack::Util::QueueTime.get_request_start(env)
              @web_service_name = web_service_name
            end

            def recordable?
              !request_start_time.nil?
            end

            def start
              @span ||= tracer.start_span('http_server.queue', # NOTE: span kind of 'proxy' is not defined
                                          with_parent_context: parent_context,
                                          # NOTE: initialize with as many attributes as possible:
                                          attributes: {
                                            'component' => 'http',
                                            'service' => web_service_name,
                                            # NOTE: dd-trace-rb differences:
                                            # 'trace.span_type' => (http) 'proxy'
                                            'start_time' => request_start_time
                                          })
            end

            def finish
              span&.finish
            end

            private

            attr_reader :env,
                        :parent_context,
                        :request_start_time,
                        :span,
                        :tracer,
                        :web_service_name
          end
        end
      end
    end
  end
end
