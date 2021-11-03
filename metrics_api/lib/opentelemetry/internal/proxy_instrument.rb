# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    class ProxyInstrument
      def initialize(kind, name, unit, desc)
        @kind = kind
        @name = name
        @unit = unit
        @desc = desc
        @delegate = nil
      end

      def upgrade_with(meter)
        @delegate = meter.send("create_#{@kind}", @name, unit: @unit, description: @desc)
      end

      def add(amount, attributes: nil)
        @delegate.add(amount, attributes: attributes) unless @delegate.nil?
      end

      def record(amount, attributes: nil)
        @delegate.record(amount, attributes: attributes) unless @delegate.nil?
      end
    end
  end
end
