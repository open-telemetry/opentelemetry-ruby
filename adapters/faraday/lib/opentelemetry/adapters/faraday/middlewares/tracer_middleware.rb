# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Faraday
      module Middlewares
        # TracerMiddleware propagates context and instruments Faraday requests
        # by way of its middlware system
        class TracerMiddleware < ::Faraday::Middleware
          def call(env)
            return app.call(env) if disable_span_reporting?(env)

            tracer.in_span(env.url.to_s,
                           attributes: { 'component' => 'http',
                                         'http.method' => env.method,
                                         'http.url' => env.url.to_s },
                           kind: :client) do |span|
              propagate_context(span, env)

              app.call(env).on_complete { |resp| trace_response(span, resp) }
            end
          end

          # Override implementation (subclass) to determine per-connection
          # span reporting rules.
          def disable_span_reporting?(_env)
            false
          end

          private

          attr_reader :app

          # Outbound requests should only need to inject the current span.
          def propagate_context(span, env)
            propagator.inject(span.context, env.request_headers)
          end

          def propagator
            OpenTelemetry.tracer_factory.http_text_format
          end

          def tracer
            Faraday::Adapter.instance.tracer
          end

          def trace_response(span, response)
            span.set_attribute('http.status_code', response.status)
            span.set_attribute('http.status_text', response.reason_phrase)
          end
        end
      end
    end
  end
end
