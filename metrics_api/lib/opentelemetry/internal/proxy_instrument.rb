# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    class ProxyInstrument
      def initialize(kind, name, unit, desc, callback, exemplar_filter, exemplar_reservoir)
        @kind = kind
        @name = name
        @unit = unit
        @desc = desc
        @callback = callback
        @exemplar_filter      = exemplar_filter
        @exemplar_reservoir   = exemplar_reservoir
        @registered_callbacks = []
        @delegate = nil
      end

      # Creates the delegate instrument and replays any callbacks registered before the delegate existed.
      def upgrade_with(meter)
        @delegate = case @kind
                    when :counter, :histogram, :up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, exemplar_filter: @exemplar_filter, exemplar_reservoir: @exemplar_reservoir)
                    when :observable_counter, :observable_gauge, :observable_up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, exemplar_filter: @exemplar_filter, exemplar_reservoir: @exemplar_reservoir, callback: @callback)
                    end
        @registered_callbacks.each { |callback| @delegate.register_callback(callback) }
      end

      # Delegates to the underlying instrument, a no-op until the delegate is set.
      def add(amount, attributes: nil)
        @delegate&.add(amount, attributes: attributes)
      end

      # Delegates to the underlying instrument, a no-op until the delegate is set.
      def record(amount, attributes: nil)
        @delegate&.record(amount, attributes: attributes)
      end

      # Delegates to the underlying instrument, or queues the callback until the delegate is set.
      def register_callback(callback)
        if @delegate
          @delegate.register_callback(callback)
        else
          @registered_callbacks << callback
        end
      end

      # Delegates to the underlying instrument, or removes the callback from the queue.
      def unregister(callback)
        if @delegate
          @delegate.unregister(callback)
        else
          @registered_callbacks.delete(callback)
        end
      end
    end
  end
end
