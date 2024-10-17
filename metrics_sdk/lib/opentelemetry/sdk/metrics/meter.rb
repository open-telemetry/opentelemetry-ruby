# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {Meter} is the SDK implementation of {OpenTelemetry::Metrics::Meter}.
      class Meter < OpenTelemetry::Metrics::Meter
        NAME_REGEX = /\A[a-zA-Z][-.\w]{0,62}\z/

        # @api private
        #
        # Returns a new {Meter} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        #
        # @return [Meter]
        def initialize(name, version, meter_provider)
          @mutex = Mutex.new
          @instrument_registry = {}
          @instrumentation_scope = InstrumentationScope.new(name, version)
          @meter_provider = meter_provider
        end

        # @api private
        def add_metric_reader(metric_reader)
          @instrument_registry.each_value do |instrument|
            instrument.register_with_new_metric_store(metric_reader.metric_store)
          end
        end

        def create_instrument(kind, name, unit, description, callback)
          raise InstrumentNameError if name.nil?
          raise InstrumentNameError if name.empty?
          raise InstrumentNameError unless NAME_REGEX.match?(name)
          raise InstrumentUnitError if unit && (!unit.ascii_only? || unit.size > 63)
          raise InstrumentDescriptionError if description && (description.size > 1023 || !utf8mb3_encoding?(description.dup))

          super do
            case kind
            when :counter then OpenTelemetry::SDK::Metrics::Instrument::Counter.new(name, unit, description, @instrumentation_scope, @meter_provider)
            when :observable_counter then OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter.new(name, unit, description, callback, @instrumentation_scope, @meter_provider)
            when :histogram then OpenTelemetry::SDK::Metrics::Instrument::Histogram.new(name, unit, description, @instrumentation_scope, @meter_provider)
            when :observable_gauge then OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge.new(name, unit, description, callback, @instrumentation_scope, @meter_provider)
            when :up_down_counter then OpenTelemetry::SDK::Metrics::Instrument::UpDownCounter.new(name, unit, description, @instrumentation_scope, @meter_provider)
            when :observable_up_down_counter then OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter.new(name, unit, description, callback, @instrumentation_scope, @meter_provider)
            end
          end
        end

        def utf8mb3_encoding?(string)
          string.force_encoding('UTF-8').valid_encoding? &&
            string.each_char { |c| return false if c.bytesize >= 4 }
        end
      end
    end
  end
end
