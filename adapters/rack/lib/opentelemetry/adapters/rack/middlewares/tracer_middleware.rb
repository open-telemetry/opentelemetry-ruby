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
              @allowed_rack_request_headers ||= Array(config[:allowed_request_headers]).each_with_object({}) do |header, memo|
                memo["HTTP_#{header.to_s.upcase.gsub(/[-\s]/, '_')}"] = build_attribute_name('http.request.headers.', header)
              end
            end

            def allowed_response_headers
              @allowed_response_headers ||= Array(config[:allowed_response_headers]).each_with_object({}) do |header, memo|
                memo[header] = build_attribute_name('http.response.headers.', header)
                memo[header.to_s.upcase] = build_attribute_name('http.response.headers.', header)
              end
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
              @allowed_response_headers = nil
            end
          end

          EMPTY_HASH = {}.freeze

          def initialize(app)
            @app = app
          end

          def call(env)
            extracted_context = OpenTelemetry.propagation.extract(env)
            frontend_context = create_frontend_span(env, extracted_context)
            request_context = create_request_span(env, frontend_context || extracted_context)
            request_span = request_context[current_span_key]

            # restore extracted context in this process:
            OpenTelemetry::Context.with_current(request_context) do
              begin
                @app.call(env).tap do |status, headers, response|
                  set_attributes_after_request(request_span, status, headers, response)
                end
              rescue StandardError => e
                record_and_reraise_error(e, request_span: request_span)
              ensure
                finish_span(frontend_context)
                finish_span(request_context)
              end
            end
          end

          private

          def create_request_span(env, context)
            original_env = env.dup

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

            # Sets as many attributes as are available before control
            # is handed off to next middleware.
            span = tracer.start_span(request_span_name,
                                     with_parent_context: context,
                                     # NOTE: try to set as many attributes via 'attributes' argument
                                     #       instead of via span.set_attribute
                                     attributes: request_span_attributes(env: env),
                                     kind: :server)

            context.set_value(current_span_key, span)
          end

          # return Context with the frontend span as the current span
          def create_frontend_span(env, extracted_context)
            # NOTE: get_request_start may return nil
            request_start_time = OpenTelemetry::Adapters::Rack::Util::QueueTime.get_request_start(env)
            record_frontend_span = config[:record_frontend_span] && !request_start_time.nil?

            return unless record_frontend_span

            # NOTE: start_span assumes context is managed explicitly,
            #       while in_span and with_span activate span automatically
            span = tracer.start_span('http_server.queue', # NOTE: span kind of 'proxy' is not defined
                                     with_parent_context: extracted_context,
                                     # NOTE: initialize with as many attributes as possible:
                                     attributes: {
                                       'component' => 'http',
                                       'service' => config[:web_service_name],
                                       'start_time' => request_start_time
                                     },
                                     kind: :server)

            extracted_context.set_value(current_span_key, span)
          end

          def finish_span(context)
            context[current_span_key]&.finish if context
          end

          def current_span_key
            OpenTelemetry::Trace::Propagation::ContextKeys.current_span_key
          end

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
          def request_span_attributes(env:)
            rack_request = ::Rack::Request.new(env)

            {
              'component' => 'http',
              'http.method' => env['REQUEST_METHOD'],
              'http.url' => rack_request.url,
              'http.host' => env['HOST'],
              'http.scheme' => env['rack.url_scheme'],
              # e.g., "/webshop/articles/4?s=1":
              'http.target' => rack_request.fullpath,
              'http.base_url' => rack_request.base_url # NOTE: 'http.base_url' isn't officially defined
            }.merge(allowed_request_headers(env))
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
            return EMPTY_HASH if self.class.allowed_rack_request_headers.empty?

            {}.tap do |result|
              self.class.allowed_rack_request_headers.each do |key, value|
                result[value] = env[key] if env.key?(key)
              end
            end
          end

          # @return Hash
          def allowed_response_headers(headers)
            return EMPTY_HASH if headers.nil?
            return EMPTY_HASH if self.class.allowed_response_headers.empty?

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
