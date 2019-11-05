# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of Meter.
    class Meter
      NOOP_LABEL_SET = Object.new
      private_constant(:NOOP_LABEL_SET)

      def record_batch(*measurements, label_set: nil); end

      # Canonicalizes labels, returning an opaque {LabelSet} object.
      #
      # @param [Hash<String, String>] labels
      # @return [LabelSet]
      def labels(labels)
        NOOP_LABEL_SET
      end

      # Create and return a floating point gauge.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] monotonic Whether the gauge accepts only monotonic updates. Defaults to false.
      # @return [FloatGauge]
      def create_float_gauge(name, description: nil, unit: nil, recommended_label_keys: nil, monotonic: false)
        raise ArgumentError if name.nil?

        Instruments::FloatGauge.new
      end

      # Create and return an integer gauge.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] monotonic Whether the gauge accepts only monotonic updates. Defaults to false.
      # @return [IntegerGauge]
      def create_integer_gauge(name, description: nil, unit: nil, recommended_label_keys: nil, monotonic: false)
        raise ArgumentError if name.nil?

        Instruments::IntegerGauge.new
      end

      # Create and return a floating point counter.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] monotonic Whether the counter accepts only monotonic updates. Defaults to true.
      # @return [FloatCounter]
      def create_float_counter(name, description: nil, unit: nil, recommended_label_keys: nil, monotonic: true)
        raise ArgumentError if name.nil?

        Instruments::FloatCounter.new
      end

      # Create and return an integer counter.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] monotonic Whether the counter accepts only monotonic updates. Defaults to true.
      # @return [IntegerCounter]
      def create_integer_counter(name, description: nil, unit: nil, recommended_label_keys: nil, monotonic: true)
        raise ArgumentError if name.nil?

        Instruments::IntegerCounter.new
      end

      # Create and return a floating point measure.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] absolute Whether the measure accepts only non-negative updates. Defaults to true.
      # @return [FloatMeasure]
      def create_float_measure(name, description: nil, unit: nil, recommended_label_keys: nil, absolute: true)
        raise ArgumentError if name.nil?

        Instruments::FloatMeasure.new
      end

      # Create and return an integer measure.
      #
      # @param [String] name Name of the metric. See {Meter} for required metric name syntax.
      # @param [optional String] description Descriptive text documenting the instrument.
      # @param [optional String] unit Unit specified according to http://unitsofmeasure.org/ucum.html.
      # @param [optional Enumerable<String>] recommended_label_keys Recommended grouping keys for this instrument.
      # @param [optional Boolean] absolute Whether the measure accepts only non-negative updates. Defaults to true.
      # @return [IntegerMeasure]
      def create_integer_measure(name, description: nil, unit: nil, recommended_label_keys: nil, absolute: true)
        raise ArgumentError if name.nil?

        Instruments::IntegerMeasure.new
      end
    end
  end
end
