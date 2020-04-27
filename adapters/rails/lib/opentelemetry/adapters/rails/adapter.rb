# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/adapters/rack/middlewares/tracer_middleware'
# require_relative 'middlewares'

module OpenTelemetry
  module Adapters
    module Rails
      class Railtie < Rails::Railtie
        initializer 'opentelemetry.before_initialize' do |app|
          app.middleware.insert_before(0, OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware)

        end
      end
      # The Adapter class contains logic to detect and install the Rails
      # instrumentation adapter
      class Adapter < OpenTelemetry::Instrumentation::Adapter
        install do |_|

          # ::ActiveSupport.on_load(:before_initialize) do
          #   self.middleware.insert_before(0, OpenTelemetry::Adapters::Rack::Middlewares::TracerMiddleware)
          # end
        end

        present do
          defined?(::Rails)
        end
      end
    end
  end
end
