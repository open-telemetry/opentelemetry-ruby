# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of Baggage::Manager
    class NoopManager
      NOOP_BUILDER = NoopBuilder.new
      EMPTY_HASH = {}.freeze
      private_constant(:NOOP_BUILDER, :EMPTY_HASH)

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
        EMPTY_HASH
      end

      def raw_entries(context: Context.current)
        EMPTY_HASH
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
