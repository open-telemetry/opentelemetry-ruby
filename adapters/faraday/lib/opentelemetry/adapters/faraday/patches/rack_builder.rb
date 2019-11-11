# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require_relative '../middlewares/tracer_middleware'

module OpenTelemetry
  module Adapters
    module Faraday
      module Patches
        # Module to be prepended to force Faraday to use the middleware by
        # default so the user doesn't have to call `use` for every connection.
        module RackBuilder
          def adapter(*args)
            use(:open_telemetry) unless @handlers.any? do |handler|
              handler.klass == Middlewares::TracerMiddleware
            end

            super
          end
        end
      end
    end
  end
end
