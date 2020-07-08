# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      module Middlewares
        # TracerMiddleware propagates context and instruments Faraday requests
        # by way of its middlware system
        class TracerMiddleware < ::Faraday::Middleware
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

          def call(env)
            http_method = HTTP_METHODS_SYMBOL_TO_STRING[env.method]

            tracer.in_span(
              "HTTP #{http_method}",
              attributes: {
                'http.method' => http_method,
                'http.url' => env.url.to_s
              },
              kind: :client
            ) do |span|
              OpenTelemetry.propagation.http.inject(env.request_headers)

              app.call(env).on_complete { |resp| trace_response(span, resp) }
            end
          end

          private

          attr_reader :app

          def tracer
            Faraday::Instrumentation.instance.tracer
          end

          def trace_response(span, response)
            span.set_attribute('http.status_code', response.status)
            span.set_attribute('http.status_text', response.reason_phrase)
            span.status = OpenTelemetry::Trace::Status.http_to_status(
              response.status
            )
          end
        end
      end
    end
  end
end
