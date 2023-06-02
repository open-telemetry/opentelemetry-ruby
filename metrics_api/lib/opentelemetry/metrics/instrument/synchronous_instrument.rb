# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # https://opentelemetry.io/docs/specs/otel/metrics/api/#synchronous-instrument-api
      class SynchronousInstrument
        attr_reader :name, :unit, :description, :advice

        # @api private
        def initialize(name, unit: nil, description: nil, advice: nil)
          @name = name
          @unit = unit || ''
          @description = description || ''
          @advice = advice || {}
        end
      end
    end
  end
end
