# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # Metric is a base class for various types of metrics. Metric subclasses are specialized for the type of a time series that Metric holds.
    # Metric is constructed from the Meter class by providing set of Metric identifiers like name and set of label keys.
    class Metric
      # @api private
      def initialize(label_keys_size:)
        @label_keys_size = label_keys_size
      end

      # TODO: spec calls this 'get_or_create_time_series', which seems excessively wordy.
      def time_series_for(label_values)
        raise ArgumentError if @label_keys_size != (label_values&.size || 0)
        raise ArgumentError if label_values&.any?(nil)

        default_time_series
      end

      def remove_time_series(label_values)
        raise ArgumentError if label_values.nil?
      end

      def callback=(callable)
        raise ArgumentError unless callable&.respond_to?(:call)
      end

      def clear; end
    end

    # DoubleCounter metric aggregates instantaneous non-integral values. Cumulative values can go up or stay the same, but can never go down. Cumulative values cannot be negative.
    class DoubleCounter < Metric
      def default_time_series
        DoubleCounterTimeSeries.new
      end
    end

    # LongCounter metric aggregates instantaneous integral values. Cumulative values can go up or stay the same, but can never go down. Cumulative values cannot be negative.
    class LongCounter < Metric
      def default_time_series
        LongCounterTimeSeries.new
      end
    end

    # DoubleGauge metric aggregates instantaneous non-integral values. Cumulative value can go both up and down. DoubleGauge values can be negative.
    class DoubleGauge < Metric
      def default_time_series
        DoubleGaugeTimeSeries.new
      end
    end

    # LongGauge metric aggregates instantaneous integral values. Cumulative value can go both up and down. LongGauge values can be negative.
    class LongGauge < Metric
      def default_time_series
        LongGaugeTimeSeries.new
      end
    end
  end
end
