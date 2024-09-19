# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Instrument
        # {Gauge} is the SDK implementation of {OpenTelemetry::Metrics::Gauge}.
        class Gauge < OpenTelemetry::SDK::Metrics::Instrument::SynchronousInstrument
          # Returns the instrument kind as a Symbol
          #
          # @return [Symbol]
          def instrument_kind
            :gauge
          end

          # Increment or decremt the Gauge by a fixed amount.
          #
          # @param [numeric] value The current absolute value.
          # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
          #   Values must be non-nil and (array of) string, boolean or numeric type.
          #   Array values must not contain nil elements and all elements must be of
          #   the same basic type (string, numeric, boolean).
          def record(value, attributes: {})
            # TODO: When the metrics SDK stabilizes and is merged into the main SDK,
            # we can leverage the SDK Internal validation classes to enforce this:
            # https://github.com/open-telemetry/opentelemetry-ruby/blob/6bec625ef49004f364457c26263df421526b60d6/sdk/lib/opentelemetry/sdk/internal.rb#L47
            update(amount, attributes)
            nil
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
            nil
          end

          private

          # TODO: replace the default aggregation to LastValue
          def default_aggregation
            OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
          end
        end
      end
    end
  end
end
