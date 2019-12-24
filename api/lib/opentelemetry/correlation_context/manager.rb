# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module CorrelationContext
    # No op implementation of CorrelationContext::Manager
    class Manager
      def set_value(key, value, context: Context.current)
        context
      end

      def value(key, context: Context.current)
        nil
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
