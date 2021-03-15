# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    # No op implementation of Baggage::Manager
    class Manager
      NOOP_BUILDER = Builder.new
      EMPTY_ENTRIES = {}.freeze
      private_constant(:NOOP_BUILDER, :EMPTY_ENTRIES)

      def build(context: Context.current)
        yield NOOP_BUILDER
        context
      end

      def set_entry(key, value, metadata: nil, context: Context.current)
        context
      end

      def entry(key, context: Context.current)
        nil
      end

      def entries(context: Context.current)
        EMPTY_ENTRIES
      end

      def remove_entry(key, context: Context.current)
        context
      end

      def clear(context: Context.current)
        context
      end
    end
  end
end
