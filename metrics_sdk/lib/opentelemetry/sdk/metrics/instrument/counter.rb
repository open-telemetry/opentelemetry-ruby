# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {Counter} is the SDK implementation of {OpenTelemetry::Metrics::Counter}.
        class Counter < OpenTelemetry::SDK::Metrics::Instrument::SynchronousInstrument
          DEFAULT_AGGREGATION = OpenTelemetry::SDK::Metrics::Aggregation::SUM

          # Returns the instrument kind as a Symbol
          #
          # @return [Symbol]
          def instrument_kind
            :counter
          end

          # Increment the Counter by a fixed amount.
          #
          # @param [numeric] increment The increment amount, which MUST be a non-negative numeric value.
          # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
          #   Values must be non-nil and (array of) string, boolean or numeric type.
          #   Array values must not contain nil elements and all elements must be of
          #   the same basic type (string, numeric, boolean).
          def add(increment, attributes: {})
            if increment.negative?
              OpenTelemetry.logger.warn("#{@name} received a negative value")
            else
              update(
                OpenTelemetry::Metrics::Measurement.new(increment, attributes),
                DEFAULT_AGGREGATION
              )
            end
            nil
          rescue => e
            OpenTelemetry.handle_error(exception: e)
            nil
          end
        end
      end
    end
  end
end
