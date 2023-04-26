# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # https://opentelemetry.io/docs/reference/specification/metrics/api/#asynchronous-instrument-api
      class AsynchronousInstrument
        attr_reader :name, :unit, :description, :callback

        # @api private
        def initialize(name, unit: nil, description: nil, callback: nil)
          @name = name
          @unit = unit || ''
          @description = description || ''
          @callback = callback ? Array(callback) : []
        end

        # @param callback [Proc, Array<Proc>]
        #   Callback functions should:
        #   - be reentrant safe;
        #   - not take an indefinite amount of time;
        #   - not make duplicate observations (more than one Measurement with the same attributes)
        #     across all registered callbacks;
        def register_callback(callback)
          @callback.concat(Array(callback))
        end

        # @param callback [Proc, Array<Proc>]
        #   Callback functions should:
        #   - be reentrant safe;
        #   - not take an indefinite amount of time;
        #   - not make duplicate observations (more than one Measurement with the same attributes)
        #     across all registered callbacks;
        def unregister_callback(callback)
          @callback -= Array(callback)
        end
      end
    end
  end
end
