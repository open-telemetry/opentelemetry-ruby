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

      NAME_REGEX = /\A[a-zA-Z][-.\w]{0,62}\z/

      private_constant(:COUNTER, :OBSERVABLE_COUNTER, :HISTOGRAM, :OBSERVABLE_GAUGE, :UP_DOWN_COUNTER, :OBSERVABLE_UP_DOWN_COUNTER)

      DuplicateInstrumentError = Class.new(OpenTelemetry::Error)
      InstrumentNameError = Class.new(OpenTelemetry::Error)
      InstrumentUnitError = Class.new(OpenTelemetry::Error)
      InstrumentDescriptionError = Class.new(OpenTelemetry::Error)

      def initialize
        @mutex = Mutex.new
        @instrument_registry = {}
      end

      # {https://opentelemetry.io/docs/specs/otel/metrics/api/#counter Counter} is a synchronous Instrument which supports non-negative increments.
      #
      # With this api call:
      #
      #   exception_counter = meter.create_counter("exceptions",
      #                                            description: "number of exceptions caught",
      #                                            unit: 's')
      #
      # @param name [String] the name of the counter
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of counter, it will be stored in instrument_registry
      def create_counter(name, unit: nil, description: nil)
        create_instrument(:counter, name, unit, description, nil) { COUNTER }
      end

      # Histogram is a synchronous Instrument which can be used to report arbitrary values that are likely
      # to be statistically meaningful. It is intended for statistics such as histograms,
      # summaries, and percentiles.
      #
      # With this api call:
      #
      #   http_server_duration = meter.create_histogram("http.server.duration",
      #                                                 description: "measures the duration of the inbound HTTP request",
      #                                                 unit: "s")
      #
      # @param name [String] the name of the histogram
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of histogram, it will be stored in instrument_registry
      def create_histogram(name, unit: nil, description: nil)
        create_instrument(:histogram, name, unit, description, nil) { HISTOGRAM }
      end

      # UpDownCounter is a synchronous Instrument which supports increments and decrements.
      #
      # With this api call:
      #
      #   items_counter = meter.create_up_down_counter("store.inventory",
      #                                                description: "the number of the items available",
      #                                                unit: "s")
      #
      # @param name [String] the name of the up_down_counter
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of up_down_counter, it will be stored in instrument_registry
      def create_up_down_counter(name, unit: nil, description: nil)
        create_instrument(:up_down_counter, name, unit, description, nil) { UP_DOWN_COUNTER }
      end

      # ObservableCounter is an asynchronous Instrument which reports monotonically
      # increasing value(s) when the instrument is being observed.
      #
      # With this api call:
      #
      #   pf_callback = -> { # collect metrics here }
      #   meter.create_observable_counter("PF",
      #                                    pf_callback,
      #                                    description: "process page faults",
      #                                    unit: 'ms')
      #
      #
      # @param name [String] the name of the observable_counter
      # @param callback [Proc] the callback function that used to collect metrics
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of observable_counter, it will be stored in instrument_registry
      def create_observable_counter(name, callback:, unit: nil, description: nil)
        create_instrument(:observable_counter, name, unit, description, callback) { OBSERVABLE_COUNTER }
      end

      # ObservableGauge is an asynchronous Instrument which reports non-additive value(s)
      # (e.g. the room temperature - it makes no sense to report the temperature value
      # from multiple rooms and sum them up) when the instrument is being observed.
      #
      # With this api call:
      #
      #   pf_callback = -> { # collect metrics here }
      #   meter.create_observable_counter("cpu.frequency",
      #                                    pf_callback,
      #                                    description: "the real-time CPU clock speed",
      #                                    unit: 'ms')
      #
      #
      # @param name [String] the name of the observable_gauge
      # @param callback [Proc] the callback function that used to collect metrics
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of observable_gauge, it will be stored in instrument_registry
      def create_observable_gauge(name, callback:, unit: nil, description: nil)
        create_instrument(:observable_gauge, name, unit, description, callback) { OBSERVABLE_GAUGE }
      end

      # ObservableUpDownCounter is an asynchronous Instrument which reports additive value(s)
      # (e.g. the process heap size - it makes sense to report the heap size from multiple processes
      # and sum them up, so we get the total heap usage) when the instrument is being observed.
      #
      # With this api call:
      #
      #   pf_callback = -> { # collect metrics here }
      #   meter.create_observable_up_down_counter("process.workingset",
      #                                            pf_callback,
      #                                            description: "process working set",
      #                                            unit: 'KB')
      #
      #
      # @param name [String] the name of the observable_up_down_counter
      # @param callback [Proc] the callback function that used to collect metrics
      # @param unit [optional String] an optional string provided by user.
      # @param description [optional String] an optional free-form text provided by user.
      #
      # @return [nil] after creation of observable_up_down_counter, it will be stored in instrument_registry
      def create_observable_up_down_counter(name, callback:, unit: nil, description: nil)
        create_instrument(:observable_up_down_counter, name, unit, description, callback) { OBSERVABLE_UP_DOWN_COUNTER }
      end

      private

      def create_instrument(kind, name, unit, description, callback)
        raise InstrumentNameError if name.nil?
        raise InstrumentNameError if name.empty?
        raise InstrumentNameError unless NAME_REGEX.match?(name)
        raise InstrumentUnitError if unit && (!unit.ascii_only? || unit.size > 63)
        raise InstrumentDescriptionError if description && (description.size > 1023 || !utf8mb3_encoding?(description.dup))

        @mutex.synchronize do
          OpenTelemetry.logger.warn("duplicate instrument registration occurred for instrument #{name}") if @instrument_registry.include? name

          @instrument_registry[name] = yield
        end
      end

      def utf8mb3_encoding?(string)
        string.force_encoding('UTF-8').valid_encoding? &&
          string.each_char { |c| return false if c.bytesize >= 4 }
      end
    end
  end
end
