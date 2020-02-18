# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Excon
      module Middlewares
        # Excon middleware for instrumentation
        class TracerMiddleware < ::Excon::Middleware::Base
          HTTP_METHODS_SYMBOL_TO_STRING = {
            connect: 'CONNECT',
            delete: 'DELETE',
            get: 'GET',
            head: 'HEAD',
            options: 'OPTIONS',
            patch: 'PATCH',
            post: 'POST',
            put: 'PUT',
            trace: 'TRACE'
          }.freeze

          def request_call(datum) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            begin
              unless datum.key?(:otel_span)
                http_method = HTTP_METHODS_SYMBOL_TO_STRING[datum[:method]]

                tracer.start_span(
                  "HTTP #{http_method}",
                  attributes: {
                    'component' => 'http',
                    'http.host' => datum[:host],
                    'http.method' => http_method,
                    'http.scheme' => datum[:scheme],
                    'http.target' => datum[:path]
                  },
                  kind: :client
                ).tap do |span|
                  datum[:otel_span] = span
                  tracer.with_span(span) do
                    OpenTelemetry.propagation.inject(datum[:headers])
                  end
                end
              end
            rescue StandardError => e
              OpenTelemetry.logger.debug(e.message)
            end

            @stack.request_call(datum)
          end

          def response_call(datum)
            @stack.response_call(datum).tap do |d|
              handle_response(d)
            end
          end

          def error_call(datum)
            handle_response(datum)
            @stack.error_call(datum)
          end

          # Returns a copy of the default stack with the trace middleware injected
          def self.around_default_stack
            ::Excon.defaults[:middlewares].dup.tap do |default_stack|
              # If the default stack contains a version of the trace middleware already...
              existing_trace_middleware = default_stack.find { |m| m <= TracerMiddleware }
              default_stack.delete(existing_trace_middleware) if existing_trace_middleware

              # Inject after the ResponseParser middleware
              response_middleware_index = default_stack.index(::Excon::Middleware::ResponseParser).to_i
              default_stack.insert(response_middleware_index + 1, self)
            end
          end

          private

          def handle_response(datum) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            if datum.key?(:otel_span)
              datum[:otel_span].tap do |span|
                return span if span.end_timestamp

                if datum.key?(:response)
                  response = datum[:response]
                  span.set_attribute('http.status_code', response[:status])
                  span.set_attribute('http.status_text', response[:reason_phrase])
                  span.status = OpenTelemetry::Trace::Status.http_to_status(
                    response[:status]
                  )
                end

                if datum.key?(:error)
                  span.status = OpenTelemetry::Trace::Status.new(
                    OpenTelemetry::Trace::Status::UNKNOWN_ERROR,
                    description: "Request has failed: #{datum[:error]}"
                  )
                end

                span.finish
                datum.delete(:otel_span)
              end
            end
          rescue StandardError => e
            OpenTelemetry.logger.debug(e.message)
          end

          def tracer
            Excon::Adapter.instance.tracer
          end
        end
      end
    end
  end
end
