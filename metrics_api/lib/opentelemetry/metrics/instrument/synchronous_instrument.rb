# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # https://opentelemetry.io/docs/reference/specification/metrics/api/#synchronous-instrument-api
      class SynchronousInstrument
        attr_reader :name, :unit, :description

        # @api private
        def initialize(name, unit: nil, description: nil)
          @name = name
          @unit = unit || ''
          @description = description || ''
        end
      end
    end
  end
end
