# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module CorrelationContext
      # Manages correlation context
      class Manager
        CORRELATION_CONTEXT_KEY = OpenTelemetry::CorrelationContext::Propagation::ContextKeys.correlation_context_key
        EMPTY_CORRELATION_CONTEXT = {}.freeze
        private_constant(:CORRELATION_CONTEXT_KEY, :EMPTY_CORRELATION_CONTEXT)

        # Used to chain modifications to correlation context. The result is a
        # context with an updated correlation context. If only a single
        # modification is being made to correlation context, use the other
        # methods on +Manager+, if multiple modifications are being made, use
        # this one.
        #
        # @param [optional Context] context The context to update with with new
        #   modified correlation context. Defaults to +Context.current+
        # @return [Context]
        def build_context(context: Context.current)
          builder = Builder.new(correlations_for(context).dup)
          yield builder
          context.set_value(CORRELATION_CONTEXT_KEY, builder.entries)
        end

        # Returns a new context with empty correlations
        #
        # @param [optional Context] context Context to clear correlations from. Defaults
        #   to +Context.current+
        # @return [Context]
        def clear(context: Context.current)
          context.set_value(CORRELATION_CONTEXT_KEY, EMPTY_CORRELATION_CONTEXT)
        end

        # Returns the corresponding correlation value (or nil) for key
        #
        # @param [String] key The lookup key
        # @param [optional Context] context The context from which to retrieve
        #   the key.
        #   Defaults to +Context.current+
        # @return [String]
        def value(key, context: Context.current)
          correlations_for(context)[key]
        end

        # Returns the correlations
        #
        # @param [optional Context] context The context from which to retrieve
        #   the correlations.
        #   Defaults to +Context.current+
        # @return [Hash]
        def values(context: Context.current)
          correlations_for(context).dup.freeze
        end

        # Returns a new context with new key-value pair
        #
        # @param [String] key The key to store this value under
        # @param [String] value String value to be stored under key
        # @param [optional Context] context The context to update with new
        #   value. Defaults to +Context.current+
        # @return [Context]
        def set_value(key, value, context: Context.current)
          new_correlations = correlations_for(context).dup
          new_correlations[key] = value
          context.set_value(CORRELATION_CONTEXT_KEY, new_correlations)
        end

        # Returns a new context with value at key removed
        #
        # @param [String] key The key to remove
        # @param [optional Context] context The context to remove correlation
        #   from. Defaults to +Context.current+
        # @return [Context]
        def remove_value(key, context: Context.current)
          correlations = correlations_for(context)
          return context unless correlations.key?(key)

          new_correlations = correlations.dup
          new_correlations.delete(key)
          context.set_value(CORRELATION_CONTEXT_KEY, new_correlations)
        end

        private

        def correlations_for(context)
          context.value(CORRELATION_CONTEXT_KEY) || EMPTY_CORRELATION_CONTEXT
        end
      end
    end
  end
end
