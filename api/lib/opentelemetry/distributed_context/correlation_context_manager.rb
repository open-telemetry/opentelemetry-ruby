# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module DistributedContext
    # Minimal implementation of a correlation context manager
    class CorrelationContextManager
      CORRELATION_CONTEXT_KEY = Propagation::ContextKeys.span_context_key
      EMPTY_CORRELATION_CONTEXT = CorrelationContext.new.freeze

      # Returns correlation context from the currently active {Context}
      #
      # @return [CorrelationContext]
      def current_context
        Context.value(CORRELATION_CONTEXT_KEY) || EMPTY_CORRELATION_CONTEXT
      end

      # Execute block with current correlation context active
      #
      # @param [CorrelationContext] coOpenTelemetry::DistributedContextrrelation_context The correlation context
      #   to make current
      def with_current_context(correlation_context)
        Context.with_value(CORRELATION_CONTEXT_KEY, correlation_context) { |c| yield c }
      end

      def create_context(parent: nil, labels: nil, remove_keys: nil)
        EMPTY_CORRELATION_CONTEXT
      end

      # Returns no-op binary format
      def binary_format
        # @todo
      end

      # Returns no-op http_text_format
      def http_text_format
        # @todo
      end
    end
  end
end
