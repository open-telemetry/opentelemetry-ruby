# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Faraday
      module Middlewares
        class TracerMiddleware < ::Faraday::Middleware
          def call(env)
            tracer.in_span(env.url.to_s,
                          attributes: { 'component' => 'http',
                                        'http.method' => env.method },
                          kind: :client) do |span|
              trace_request(span, env)

              app.call(env).on_complete { |resp| trace_response(span, resp) }
            end
          end

          private

          attr_reader :app

          def tracer
            Faraday::Adapter.tracer
          end

          def trace_request(span, env)
            span.set_attribute('http.url', env.url.to_s)
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
