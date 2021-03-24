# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Faraday
      # The Instrumentation class contains logic to detect and install the Faraday
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          register_tracer_middleware
          use_middleware_by_default
        end

        present do
          defined?(::Faraday)
        end

        option :peer_service, default: nil, validate: :string

        private

        def require_dependencies
          require_relative 'middlewares/tracer_middleware'
          require_relative 'patches/rack_builder'
        end

        def register_tracer_middleware
          ::Faraday::Middleware.register_middleware(
            open_telemetry: Middlewares::TracerMiddleware
          )
        end

        def use_middleware_by_default
          ::Faraday::RackBuilder.prepend(Patches::RackBuilder)
        end
      end
    end
  end
end
