# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # TimeSeries is a base class for a time series.
    class TimeSeries
      def add(value); end

      def set(value); end

      # @api private
      module Double
        def add(value)
          raise ArgumentError if value.integer?

          super
        end

        def set(value)
          raise ArgumentError if value.integer?

          super
        end
      end

      # @api private
      module Long
        def add(value)
          raise ArgumentError unless value.integer?

          super
        end

        def set(value)
          raise ArgumentError unless value.integer?

          super
        end
      end

      # @api private
      module Counter
        def add(value)
          raise ArgumentError if value.negative?

          super
        end
      end

      # @api private
      module Gauge
      end

      private_constant(:Gauge, :Counter, :Long, :Double)
    end

    # A time series for a gauge of type double.
    class DoubleGaugeTimeSeries < TimeSeries
      include Double
      include Gauge
    end

    # A time series for a gauge of type long.
    class LongGaugeTimeSeries < TimeSeries
      include Long
      include Gauge
    end

    # A time series for a counter of type double.
    class DoubleCounterTimeSeries < TimeSeries
      include Double
      include Counter
    end

    # A time series for a counter of type long.
    class LongCounterTimeSeries < TimeSeries
      include Long
      include Counter
    end
  end
end
