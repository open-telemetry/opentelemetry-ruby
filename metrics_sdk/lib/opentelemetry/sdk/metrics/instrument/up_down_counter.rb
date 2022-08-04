# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {UpDownCounter} is the SDK implementation of {OpenTelemetry::Metrics::UpDownCounter}.
        class UpDownCounter < OpenTelemetry::SDK::Metrics::Instrument::SynchronousInstrument
          DEFAULT_AGGREGATION = OpenTelemetry::SDK::Metrics::Aggregation::SUM

          # Returns the instrument kind as a Symbol
          #
          # @return [Symbol]
          def instrument_kind
            :up_down_counter
          end

          # Increment or decrement the UpDownCounter by a fixed amount.
          #
          # @param [Numeric] amount The amount to be added, can be positive, negative or zero.
          # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
          #   Values must be non-nil and (array of) string, boolean or numeric type.
          #   Array values must not contain nil elements and all elements must be of
          #   the same basic type (string, numeric, boolean).
          def add(amount, attributes: nil)
            update(
              OpenTelemetry::Metrics::Measurement.new(amount, attributes),
              DEFAULT_AGGREGATION
            )
            nil
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
            nil
          end
        end
      end
    end
  end
end
