# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'opentelemetry-instrumentation-rack'

module OpenTelemetry
  module Instrumentation
    module Sinatra
      module Middlewares
        # Middleware to trace Sinatra requests
        class TracerMiddleware
          def initialize(app)
            @app = app
          end

          def call(env)
            @app.call(env)
          ensure
            trace_response(env)
          end

          def trace_response(env)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return unless span.recording?

            span.set_attribute('http.route', env['sinatra.route'].split.last) if env['sinatra.route']
            span.name = env['sinatra.route'] if env['sinatra.route']
          end
        end
      end
    end
  end
end
