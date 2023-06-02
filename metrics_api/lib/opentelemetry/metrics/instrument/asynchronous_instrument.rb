# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # https://opentelemetry.io/docs/specs/otel/metrics/api/#asynchronous-instrument-api
      class AsynchronousInstrument
        attr_reader :name, :unit, :description, :callbacks

        # @api private
        def initialize(name, unit: nil, description: nil, callbacks: nil)
          @name = name
          @unit = unit || ''
          @description = description || ''
          @callbacks = callbacks ? Array(callbacks) : []
        end

        # @param callbacks [Proc, Array<Proc>]
        #   Callback functions should:
        #   - be reentrant safe;
        #   - not take an indefinite amount of time;
        #   - not make duplicate observations (more than one Measurement with the same attributes)
        #     across all registered callbacks;
        def register_callbacks(*callbacks); end

        # @param callbacks [Proc, Array<Proc>]
        #   Callback functions should:
        #   - be reentrant safe;
        #   - not take an indefinite amount of time;
        #   - not make duplicate observations (more than one Measurement with the same attributes)
        #     across all registered callbacks;
        def unregister_callbacks(*callbacks); end
      end
    end
  end
end
