# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    class ProxyInstrument
      def initialize(kind, name, unit, desc, callable, exemplar_filter, exemplar_reservoir)
        @kind = kind
        @name = name
        @unit = unit
        @desc = desc
        @callable = callable
        @exemplar_filter    = exemplar_filter
        @exemplar_reservoir = exemplar_reservoir
        @delegate = nil
      end

      # Upgrades the proxy to a concrete instrument from the supplied meter.
      def upgrade_with(meter)
        @delegate = case @kind
                    when :counter, :histogram, :up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, exemplar_filter: @exemplar_filter, exemplar_reservoir: @exemplar_reservoir)
                    when :observable_counter, :observable_gauge, :observable_up_down_counter
                      meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, exemplar_filter: @exemplar_filter, exemplar_reservoir: @exemplar_reservoir, callback: @callback)
                    end
      end

      # Forwards an add operation to the concrete instrument when available.
      def add(amount, attributes: nil)
        @delegate&.add(amount, attributes: attributes)
      end

      # Forwards a record operation to the concrete instrument when available.
      def record(amount, attributes: nil)
        @delegate&.record(amount, attributes: attributes)
      end
    end
  end
end
