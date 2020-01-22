# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../util/queue_time'

module OpenTelemetry
  module Adapters
    module Rack
      module Middlewares
        # TODO: implement 'resource name'
        class TracerMiddleware
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
            extract_parent_context if extract_parent_context?

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

          def extract_parent_context?
            # TODO: compare to ':distributed_tracing' option name/semantics
            config[:extract_parent_context]
          end

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
              'http.base_url' => base_url # TODO: check attribute naming/semantics
            }.merge(allowed_request_headers)
          end

          def full_http_request_url
            # NOTE: dd-trace-rb has implemented 'quantization'? (which lowers url cardinality)
            #       see Datadog::Quantization::HTTP.url

            rack_request.url
          end

          # https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-http.md#name
          #
          def request_span_name
            # uri_path_value:
            env['PATH_INFO']
          end

          def base_url
            if rack_request.respond_to?(:base_url)
              rack_request.base_url
            else
              # Compatibility for older Rack versions
              rack_request.url.chomp(rack_request.fullpath)
            end
          end

          def rack_request
            @rack_request ||= ::Rack::Request.new(env)
          end

          def record_and_reraise_error(error)
            # TODO: implement span.set_error?

            # catch exceptions that may be raised in the middleware chain
            # Note: if a middleware catches an Exception without re raising,
            # the Exception cannot be recorded here.
            request_span.set_error(error) unless request_span.nil?
            raise error
          end

          def set_attributes_after_request(span, status, headers, _response)
            span.status = OpenTelemetry::Trace::Status.http_to_status(status)
            span.set_attribute('http.status_code', status)

            # TODO: set_attribute('http.route', ... if it's available
            span.set_attribute('http.status_text', ::Rack::Utils::HTTP_STATUS_CODES[status])

            allowed_response_headers(headers).each { |k, v| span.set_attribute(k, v) }
          end

          # @return Hash
          def allowed_request_headers
            {}.tap do |result|
              Array(allowed_request_header_names).each do |header|
                rack_header = "HTTP_#{header.to_s.upcase.gsub(/[-\s]/, '_')}"
                if env.key?(rack_header)
                  result[build_attribute_name('http.request.headers.', header)] = env[rack_header]
                end
              end
            end
          end

          def allowed_request_header_names
            Array(config[:allowed_request_headers])
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
                                                parent_context: parent_context)
          end

          class FrontendSpan
            def initialize(env:, tracer:, parent_context:)
              @env = env
              @tracer = tracer
              @parent_context = parent_context

              # NOTE: get_request_start may return nil
              @request_start_time = OpenTelemetry::Adapters::Rack::Util::QueueTime.get_request_start(env)
            end

            def recordable?
              !request_start_time.nil?
            end

            def start
              @span ||= tracer.start_span('http_server.queue', # TODO: check this name
                                          with_parent_context: parent_context, # TODO: check for correct parent
                                          # NOTE: initialize with as many attributes as possible:
                                          attributes: {
                                            'component' => 'http',
                                            # TODO: 'service' => config[:web_service_name]
                                            # TODO: 'span_type' => PROXY
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
                        :tracer
          end
        end
      end
    end
  end
end
