# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # The user-facing metrics API supports producing diagnostic measurements
    # using three basic kinds of instrument. "Metrics" are the thing being
    # produced -- mathematical, statistical summaries of certain observable
    # behavior in the program. "Instruments" are the devices used by the
    # program to record observations about their behavior. Therefore, we use
    # "metric instrument" to refer to a program object, allocated through the
    # API, used for recording metrics. There are three distinct instruments in
    # the Metrics API, commonly known as Counters, Gauges, and Measures.
    module Instruments
      # A float gauge instrument.
      class FloatGauge
        # Set the value of the gauge.
        #
        # @param [Float] value The value to set.
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        def set(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::FloatGauge]
        def handle(labels_or_label_set = {})
          Handles::FloatGauge.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Float] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end

      # An integer gauge instrument.
      class IntegerGauge
        def set(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::IntegerGauge]
        def handle(labels_or_label_set = {})
          Handles::IntegerGauge.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Integer] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end

      # A float counter instrument.
      class FloatCounter
        def add(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::FloatCounter]
        def handle(labels_or_label_set = {})
          Handles::FloatCounter.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Float] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end

      # An integer counter instrument.
      class IntegerCounter
        def add(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::IntegerCounter]
        def handle(labels_or_label_set = {})
          Handles::IntegerCounter.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Integer] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end

      # A float measure instrument.
      class FloatMeasure
        def record(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::FloatMeasure]
        def handle(labels_or_label_set = {})
          Handles::FloatMeasure.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Float] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end

      # An integer measure instrument.
      class IntegerMeasure
        def record(value, labels_or_label_set = {}); end

        # Obtain a handle from the instrument and label set.
        #
        # @param [optional LabelSet, Hash<String, String>] labels_or_label_set
        #   A {LabelSet} returned from {Meter#labels} or a Hash of Strings.
        # @return [Handles::IntegerMeasure]
        def handle(labels_or_label_set = {})
          Handles::IntegerMeasure.new
        end

        # Return a measurement to be recorded via {Meter#record_batch}.
        #
        # @param [Integer] value
        # @return [Object, Measurement]
        def measurement(value)
          NOOP_MEASUREMENT
        end
      end
    end
  end
end
