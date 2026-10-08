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
      # Returns a new {ProxyMeter} instance.
      #
      # @return [ProxyMeter]
      def initialize
        super
        @delegate = nil
        # Every placeholder created before the delegate is set, including repeated and
        # conflicting registrations of the same name, so that each one gets upgraded.
        @proxy_instruments = []
      end

      # Set the delegate Meter. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [Meter] meter The Meter to delegate to
      def delegate=(meter)
        @mutex.synchronize do
          if @delegate.nil?
            @delegate = meter
            @proxy_instruments.each { |instrument| instrument.upgrade_with(meter) }
            @proxy_instruments.clear
          else
            OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyMeter ignored.'
          end
        end
      end

      private

      # Does not call `super`: the base registry keys instruments by name, so a repeated
      # registration would replace an earlier placeholder that then never gets upgraded.
      def create_instrument(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir, advisory)
        @mutex.synchronize do
          if @delegate.nil?
            instrument = ProxyInstrument.new(kind, name, unit, description, callback, exemplar_filter, exemplar_reservoir, advisory)
            @proxy_instruments << instrument
            next instrument
          end

          case kind
          when :counter then @delegate.create_counter(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, advisory: advisory)
          when :histogram then @delegate.create_histogram(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, advisory: advisory)
          when :up_down_counter then @delegate.create_up_down_counter(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, advisory: advisory)
          when :gauge then @delegate.create_gauge(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, advisory: advisory)
          when :observable_counter then @delegate.create_observable_counter(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, callback: callback, advisory: advisory)
          when :observable_gauge then @delegate.create_observable_gauge(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, callback: callback, advisory: advisory)
          when :observable_up_down_counter then @delegate.create_observable_up_down_counter(name, unit: unit, description: description, exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir, callback: callback, advisory: advisory)
          end
        end
      end
    end
  end
end
