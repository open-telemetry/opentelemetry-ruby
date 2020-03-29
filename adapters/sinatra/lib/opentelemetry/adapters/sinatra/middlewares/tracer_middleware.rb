# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Sinatra
      module Middlewares
        # Middleware to trace Sinatra requests
        class TracerMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            tracer.in_span(
              env['PATH_INFO'],
              attributes: { 'component' => 'http',
                            'http.method' => env['REQUEST_METHOD'],
                            'http.url' => env['PATH_INFO'] },
              kind: :server,
              with_parent_context: parent_context(env)
            ) do |span|
              app.call(env).tap { |resp| trace_response(span, env, resp) }
            end
          end

          private

          attr_reader :app

          def parent_context(env)
            OpenTelemetry.propagation.http.extract(env)
          end

          def tracer
            OpenTelemetry::Adapters::Sinatra::Adapter.instance.tracer
          end

          def trace_response(span, env, resp)
            status, _headers, _response_body = resp

            span.set_attribute('http.status_code', status)
            span.set_attribute('http.status_text', ::Rack::Utils::HTTP_STATUS_CODES[status])
            span.set_attribute('http.route', env['sinatra.route'].split.last)
            span.status = OpenTelemetry::Trace::Status.http_to_status(status)
          end
        end
      end
    end
  end
end
