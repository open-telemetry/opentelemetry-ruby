# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'middlewares/tracer_middleware'
require_relative 'patches/rack_builder'

module OpenTelemetry
  module Adapters
    module Faraday
      class Adapter < OpenTelemetry::Adapter
        def install
          register_tracer_middleware
          use_middleware_by_default
        end

        private

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
