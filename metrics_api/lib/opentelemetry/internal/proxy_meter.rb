# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyMeter} is an implementation of {OpenTelemetry::Trace::Meter}. It is returned from
    # the ProxyMeterProvider until a delegate meter provider is installed. After the delegate
    # meter provider is installed, the ProxyMeter will delegate to the corresponding "real"
    # meter.
    class ProxyMeter < Metrics::Meter
      Key = Struct.new(:name, :version)
      private_constant(:Key)

      # Returns a new {ProxyMeter} instance.
      #
      # @return [ProxyMeter]
      def initialize
        @mutex = Mutex.new
        @registry = {}
        @delegate = nil
      end

      # Set the delegate Meter. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [Meter] meter The Meter to delegate to
      def delegate=(meter)
        unless @delegate.nil?
          OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyMeter ignored.'
          return
        end

        @mutex.synchronize do
          @delegate = meter
          @registry.each { |key, instrument| instrument.upgrade_with(meter) }
        end
      end

      def create_counter(name, unit: nil, description: nil)
        @mutex.synchronize do
          return @delegate.create_counter(name, unit: unit, description: description) unless @delegate.nil?

          create_instrument(:counter, name, unit, description)
        end
      end

      def create_observable_counter(name, unit: nil, description: nil, callback:)
        @mutex.synchronize do
          return @delegate.create_observable_counter(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

          create_observable_instrument(:observable_counter, name, unit, description, callback)
        end
      end

      def create_histogram(name, unit: nil, description: nil)
        @mutex.synchronize do
          return @delegate.create_histogram(name, unit: unit, description: description) unless @delegate.nil?

          create_instrument(:histogram, name, unit, description)
        end
      end

      def create_observable_gauge(name, unit: nil, description: nil, callback:)
        @mutex.synchronize do
          return @delegate.create_observable_gauge(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

          create_observable_instrument(:observable_gauge, name, unit, description, callback)
        end
      end

      def create_up_down_counter(name, unit: nil, description: nil)
        @mutex.synchronize do
          return @delegate.create_up_down_counter(name, unit: unit, description: description) unless @delegate.nil?

          create_instrument(:up_down_counter, name, unit, description)
        end
      end

      def create_observable_up_down_counter(name, unit: nil, description: nil, callback:)
        @mutex.synchronize do
          return @delegate.create_observable_up_down_counter(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

          create_observable_instrument(:observable_up_down_counter, name, unit, description, callback)
        end
      end

      private

      def create_instrument(kind, name, unit, description)
        raise 'hell' if @registry.include? name

        @registry[name] = ProxyInstrument.new(kind, name, unit, description)
      end

      def create_observable_instrument(kind, name, unit, description, callback)
        raise 'hell' if @registry.include? name

        @registry[name] = ProxyObservableInstrument.new(kind, name, unit, description, callback)
      end
    end
  end
end
