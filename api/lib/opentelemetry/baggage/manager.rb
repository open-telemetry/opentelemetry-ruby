# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of Baggage::Manager
    class Manager
      NOOP_BUILDER = Builder.new
      EMPTY_VALUES = {}.freeze
      private_constant(:NOOP_BUILDER, :EMPTY_VALUES)

      def build(context: Context.current)
        yield NOOP_BUILDER
        context
      end

      def set_value(key, value, metadata: nil, context: Context.current)
        context
      end

      def value(key, context: Context.current)
        nil
      end

      def values(context: Context.current)
        EMPTY_VALUES
      end

      def remove_value(key, context: Context.current)
        context
      end

      def clear(context: Context.current)
        context
      end
    end
  end
end
