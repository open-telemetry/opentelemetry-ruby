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
        def set(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
        def set(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
        def add(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
        def add(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
        def record(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
        def record(value, label_set_or_label = nil, *labels); end

        def handle(label_set_or_label = nil, *labels)
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
