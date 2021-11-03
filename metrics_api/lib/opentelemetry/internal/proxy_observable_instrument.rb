# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    class ProxyObservableInstrument
      def initialize(kind, name, unit, desc, callable)
        @kind = kind
        @name = name
        @unit = unit
        @desc = desc
        @callable = callable
        @delegate = nil
      end

      def upgrade_with(meter)
        @delegate = meter.send("create_#{@kind}", @name, unit: @unit, description: @desc, callback: @callback)
      end
    end
  end
end
