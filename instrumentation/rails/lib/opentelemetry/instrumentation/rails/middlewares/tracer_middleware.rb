# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      module Middlewares
        # TracerMiddleware propagates context and instruments Rails requests
        # by way of its middleware system
        class TracerMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            extracted_context = OpenTelemetry.propagation.http.extract(env)
            OpenTelemetry::Context.with_current(extracted_context) do
              tracer.in_span(env['PATH_INFO'], attributes: request_span_attributes(env: env), kind: :server) do |request_span|
                @app.call(env).tap do |status, headers, response|
                  set_attributes_after_request(
                    request_span,
                    env: env,
                    status: status,
                    headers: headers,
                    response: response
                  )
                end
              end
            end
          ensure
            OpenTelemetry::Trace.current_span(extracted_context).finish if extracted_context
          end

          private

          def request_destination_info(env)
            ::Rails.application.routes.router.recognize(ActionDispatch::Request.new(env)) { |_route, params| return params }
          end

          def set_attributes_after_request(span, env:, status:, headers:, response:)
            span.status = OpenTelemetry::Trace::Status.http_to_status(status)
            span.set_attribute('http.status_code', status)
            span.set_attribute('http.status_text', ::Rack::Utils::HTTP_STATUS_CODES[status])

            controller = env['action_controller.instance']
            return unless controller

            span.name = "#{controller.class.name}.#{controller.action_name}"
            span.set_attribute('rails.controller', controller.class.name)
            span.set_attribute('rails.action', controller.action_name)
          end

          def request_span_attributes(env:)
            {
              'http.method' => env['REQUEST_METHOD'],
              'http.host' => env['HTTP_HOST'] || 'unknown',
              'http.scheme' => env['rack.url_scheme'],
              'http.target' => fullpath(env)
            }
          end

          def fullpath(env)
            query_string = env['QUERY_STRING']
            path = env['SCRIPT_NAME'] + env['PATH_INFO']

            query_string.empty? ? path : "#{path}?#{query_string}"
          end

          def tracer
            OpenTelemetry::Instrumentation::Rails::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
