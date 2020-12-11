# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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
    # the Metrics API, commonly known as Counters, Observers, and Measures.
    module Instruments
      # TODO: Observers.

      # A float counter instrument.
      class FloatCounter
        def add(value, labels = {}); end

        # Obtain a handle from the instrument and labels.
        #
        # @param [optional Hash<String, String>] labels A Hash of Strings.
        # @return [Handles::FloatCounter]
        def handle(labels = {})
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
        def add(value, labels = {}); end

        # Obtain a handle from the instrument and labels.
        #
        # @param [optional Hash<String, String>] labels A Hash of Strings.
        # @return [Handles::IntegerCounter]
        def handle(labels = {})
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
        def record(value, labels = {}); end

        # Obtain a handle from the instrument and labels.
        #
        # @param [optional Hash<String, String>] labels A Hash of Strings.
        # @return [Handles::FloatMeasure]
        def handle(labels = {})
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
        def record(value, labels = {}); end

        # Obtain a handle from the instrument and labels.
        #
        # @param [optional Hash<String, String>] labels A Hash of Strings.
        # @return [Handles::IntegerMeasure]
        def handle(labels = {})
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
