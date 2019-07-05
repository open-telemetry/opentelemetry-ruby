# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # Measure is a contract between the library exposing the raw measurement and SDK aggregating these values into the
    # @see Metric. Measure is constructed from the @see Meter class by providing set of Measure identifiers.
    class Measure
      NOOP_MEASUREMENT = :__noop_measurement__

      private_constant(:NOOP_MEASUREMENT)

      def create_measurement(value)
        raise ArgumentError if value.negative?

        NOOP_MEASUREMENT
      end
    end

    # TODO: Do we want the type-specific class?
    # DoubleMeasure is a Measure creating double measurements.
    class DoubleMeasure < Measure
      def create_measurement(value)
        raise ArgumentError if value.integer?

        super
      end
    end

    # TODO: Do we want the type-specific class?
    # LongMeasure is a Measure creating long measurements.
    class LongMeasure < Measure
      def create_measurement(value)
        raise ArgumentError unless value.integer?

        super
      end
    end
  end
end
