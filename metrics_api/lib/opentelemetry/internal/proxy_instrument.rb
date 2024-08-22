# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    class ProxyInstrument
      def initialize(kind, name, unit, desc, callable, advice = {})
        @kind = kind
        @name = name
        @unit = unit
        @desc = desc
        @callable = callable
        @advice = advice
        @delegate = nil
      end

      def upgrade_with(meter)
        @delegate = case @kind
                    when :counter, :up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc)
                    when :histogram
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, advice: @advice)
                    when :observable_counter, :observable_gauge, :observable_up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, callback: @callback)
                    end
      end

      def add(amount, attributes: nil)
        @delegate&.add(amount, attributes: attributes)
      end

      def record(amount, attributes: nil)
        @delegate&.record(amount, attributes: attributes)
      end
    end
  end
end
