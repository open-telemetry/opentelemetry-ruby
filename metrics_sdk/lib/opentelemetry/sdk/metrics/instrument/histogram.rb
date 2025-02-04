# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {Histogram} is the SDK implementation of {OpenTelemetry::Metrics::Histogram}.
        class Histogram < OpenTelemetry::SDK::Metrics::Instrument::SynchronousInstrument
          # Returns the instrument kind as a Symbol
          #
          # @return [Symbol]
          def instrument_kind
            :histogram
          end

          # Updates the statistics with the specified amount.
          #
          # @param [numeric] amount The amount of the Measurement, which MUST be a non-negative numeric value.
          # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
          #   Values must be non-nil and (array of) string, boolean or numeric type.
          #   Array values must not contain nil elements and all elements must be of
          #   the same basic type (string, numeric, boolean).
          def record(amount, attributes: {})
            update(amount, attributes)
            nil
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
            nil
          end

          private

          def default_aggregation
            # This hash is assembled to avoid implicitly passing `boundaries: nil`,
            # which should be valid explicit call according to ExplicitBucketHistogram#initialize
            kwargs = {}
            kwargs[:attributes] = @attributes if @attributes
            kwargs[:boundaries] = @boundaries if @boundaries

            OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(**kwargs)
          end

          def validate_advisory_parameters(parameters)
            if (boundaries = parameters.delete(:explicit_bucket_boundaries))
              @boundaries = boundaries
            end

            super
          end
        end
      end
    end
  end
end
