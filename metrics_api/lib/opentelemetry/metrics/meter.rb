# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of Meter.
    class Meter
      NOOP_COUNTER                    = Instrument::Counter.new('no-op')
      NOOP_HISTOGRAM                  = Instrument::Histogram.new('no-op')
      NOOP_UP_DOWN_COUNTER            = Instrument::UpDownCounter.new('no-op')
      NOOP_OBSERVABLE_COUNTER         = Instrument::ObservableCounter.new('no-op')
      NOOP_OBSERVABLE_GAUGE           = Instrument::ObservableGauge.new('no-op')
      NOOP_OBSERVABLE_UP_DOWN_COUNTER = Instrument::ObservableUpDownCounter.new('no-op')

      private_constant(
        :NOOP_COUNTER,
        :NOOP_HISTOGRAM,
        :NOOP_UP_DOWN_COUNTER,
        :NOOP_OBSERVABLE_COUNTER,
        :NOOP_OBSERVABLE_GAUGE,
        :NOOP_OBSERVABLE_UP_DOWN_COUNTER
      )

      attr_reader :name, :version, :schema_url, :attributes

      # @api private
      def initialize(name, version: nil, schema_url: nil, attributes: nil)
        @name = name
        @version = version || ''
        @schema_url = schema_url || ''
        @attributes = attributes || {}

        @mutex = Mutex.new
        @instrument_registry = {}
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param advice [optional Hash] Set of recommendations aimed at assisting
      #   implementations in providing useful output with minimal configuration
      #
      # @return [Instrument::Counter]
      def create_counter(name, unit: nil, description: nil, advice: nil)
        create_instrument(:counter, name, unit, description, advice, nil) { NOOP_COUNTER }
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param advice [optional Hash] Set of recommendations aimed at assisting
      #   implementations in providing useful output with minimal configuration
      #
      # @return [Instrument::Histogram]
      def create_histogram(name, unit: nil, description: nil, advice: nil)
        create_instrument(:histogram, name, unit, description, advice, nil) { NOOP_HISTOGRAM }
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param advice [optional Hash] Set of recommendations aimed at assisting
      #   implementations in providing useful output with minimal configuration
      #
      # @return [Instrument::UpDownCounter]
      def create_up_down_counter(name, unit: nil, description: nil, advice: nil)
        create_instrument(:up_down_counter, name, unit, description, advice, nil) { NOOP_UP_DOWN_COUNTER }
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param callbacks [optional Array<Proc>]
      #   Callback functions should:
      #   - be reentrant safe;
      #   - not take an indefinite amount of time;
      #   - not make duplicate observations (more than one Measurement with the same attributes)
      #     across all registered callbacks;
      #
      # @return [Instrument::ObservableCounter]
      def create_observable_counter(name, unit: nil, description: nil, callbacks: nil)
        create_instrument(:observable_counter, name, unit, description, nil, callbacks) { NOOP_OBSERVABLE_COUNTER }
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param callbacks [optional Array<Proc>]
      #   Callback functions should:
      #   - be reentrant safe;
      #   - not take an indefinite amount of time;
      #   - not make duplicate observations (more than one Measurement with the same attributes)
      #     across all registered callbacks;
      #
      # @return [Instrument::ObservableGauge]
      def create_observable_gauge(name, unit: nil, description: nil, callbacks: nil)
        create_instrument(:observable_gauge, name, unit, description, nil, callbacks) { NOOP_OBSERVABLE_GAUGE }
      end

      # @param name [String]
      #   Must conform to the instrument name syntax:
      #   not nil or empty, case-insensitive ASCII string that matches `/\A[a-z][a-z0-9_.-]{0,62}\z/i`
      # @param unit [optional String]
      #   Must conform to the instrument unit rule:
      #   case-sensitive ASCII string with maximum length of 63 characters
      # @param description [optional String]
      #   Must conform to the instrument description rule:
      #   UTF-8 string but up to 3 bytes per charater with maximum length of 1023 characters
      # @param callbacks [optional Array<Proc>]
      #   Callback functions should:
      #   - be reentrant safe;
      #   - not take an indefinite amount of time;
      #   - not make duplicate observations (more than one Measurement with the same attributes)
      #     across all registered callbacks;
      #
      # @return [Instrument::ObservableUpDownCounter]
      def create_observable_up_down_counter(name, unit: nil, description: nil, callbacks: nil)
        create_instrument(:observable_up_down_counter, name, unit, description, nil, callbacks) { NOOP_OBSERVABLE_UP_DOWN_COUNTER }
      end

      private

      def create_instrument(kind, name, unit, description, advice, callbacks)
        name = name.downcase

        @mutex.synchronize do
          if @instrument_registry.include?(name)
            OpenTelemetry.logger.warn("duplicate instrument registration occurred for #{name}")
          end

          @instrument_registry[name] = yield
        end
      end
    end
  end
end
