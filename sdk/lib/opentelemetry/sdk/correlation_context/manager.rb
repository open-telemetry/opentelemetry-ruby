# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module CorrelationContext
      # Manages correlation context
      class Manager
        CORRELATION_CONTEXT_KEY = OpenTelemetry::CorrelationContext::Propagation::ContextKeys.span_context_key
        EMPTY_CORRELATION_CONTEXT = {}.freeze
        private_constant(:CORRELATION_CONTEXT_KEY, :EMPTY_CORRELATION_CONTEXT)

        # Returns a new context with empty correlations
        #
        # @param [Context] context
        # @return [Context]
        def clear(context)
          context.set_value(CORRELATION_CONTEXT_KEY, EMPTY_CORRELATION_CONTEXT)
        end

        # Returns the corresponding correlation value (or nil) for key
        #
        # @param [Context] context The context use to retrieve key
        # @param [String] key The lookup key
        # @return [String]
        def value(context, key)
          correlations_for(context)[key]
        end

        # Returns a new context with new key-value pair
        #
        # @param [Context] context The context to update with new value
        # @param [String] key The key to store this value under
        # @param [String] value String value to be stored under key
        # @return [Context]
        def set_value(context, key, value)
          new_correlations = correlations_for(context).dup
          new_correlations[key] = value.to_s
          context.set_value(CORRELATION_CONTEXT_KEY, new_correlations)
        end

        # Returns a new context with value at key removed
        #
        # @param [Context] context The context to remove value from
        # @param [String] key The key to remove
        # @return [Context]
        def remove_value(context, key)
          correlations = correlations_for(context)
          return context unless correlations.key?(key)

          new_correlations = correlations.dup
          new_correlations.delete(key)
          context.set_value(CORRELATION_CONTEXT_KEY, new_correlations)
        end

        # @todo
        def http_injector
          raise NotImplementedError
        end

        # @todo
        def http_extractor
          raise NotImplementedError
        end

        private

        def correlations_for(context)
          context.value(CORRELATION_CONTEXT_KEY) || EMPTY_CORRELATION_CONTEXT
        end
      end
    end
  end
end
