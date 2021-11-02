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
      attr_writer :delegate

      # Returns a new {ProxyMeter} instance.
      #
      # @return [ProxyMeter]
      def initialize
        @delegate = nil
      end

      def create_counter(name, unit: nil, description: nil)
        return @delegate.create_counter(name, unit: unit, description: description) unless @delegate.nil?

        super
      end

      def create_observable_counter(name, unit: nil, description: nil, callback:)
        return @delegate.create_observable_counter(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

        super
      end

      def create_histogram(name, unit: nil, description: nil)
        return @delegate.create_histogram(name, unit: unit, description: description) unless @delegate.nil?

        super
      end

      def create_observable_gauge(name, unit: nil, description: nil, callback:)
        return @delegate.create_observable_gauge(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

        super
      end

      def create_up_down_counter(name, unit: nil, description: nil)
        return @delegate.create_up_down_counter(name, unit: unit, description: description) unless @delegate.nil?

        super
      end

      def create_observable_up_down_counter(name, unit: nil, description: nil, callback:)
        return @delegate.create_observable_up_down_counter(name, unit: unit, description: description, callback: callback) unless @delegate.nil?

        super
      end
    end
  end
end
