# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of Meter.
    class Meter
      COUNTER = Instrument::Counter.new
      OBSERVABLE_COUNTER = Instrument::ObservableCounter.new
      HISTOGRAM = Instrument::Histogram.new
      OBSERVABLE_GAUGE = Instrument::ObservableGauge.new
      UP_DOWN_COUNTER = Instrument::UpDownCounter.new
      OBSERVABLE_UP_DOWN_COUNTER = Instrument::ObservableUpDownCounter.new

      private_constant(:COUNTER, :OBSERVABLE_COUNTER, :HISTOGRAM, :OBSERVABLE_GAUGE, :UP_DOWN_COUNTER, :OBSERVABLE_UP_DOWN_COUNTER)

      DuplicateInstrumentError = Class.new(OpenTelemetry::Error)

      def initialize
        @mutex = Mutex.new
        @registry = {}
      end

      def create_counter(name, unit: nil, description: nil)
        create_instrument(:counter, name, unit, description, nil) { COUNTER }
      end

      def create_observable_counter(name, unit: nil, description: nil, callback:)
        create_instrument(:observable_counter, name, unit, description, callback) { OBSERVABLE_COUNTER }
      end

      def create_histogram(name, unit: nil, description: nil)
        create_instrument(:histogram, name, unit, description, nil) { HISTOGRAM }
      end

      def create_observable_gauge(name, unit: nil, description: nil, callback:)
        create_instrument(:observable_gauge, name, unit, description, callback) { OBSERVABLE_GAUGE }
      end

      def create_up_down_counter(name, unit: nil, description: nil)
        create_instrument(:up_down_counter, name, unit, description, nil) { UP_DOWN_COUNTER }
      end

      def create_observable_up_down_counter(name, unit: nil, description: nil, callback:)
        create_instrument(:observable_up_down_counter, name, unit, description, callback) { OBSERVABLE_UP_DOWN_COUNTER }
      end

      private

      def create_instrument(kind, name, unit, description, callback)
        @mutex.synchronize do
          raise DuplicateInstrumentError if @registry.include? name

          @registry[name] = yield
        end
      end
    end
  end
end
