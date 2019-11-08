# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Baggage
      # Manages baggage context
      module Manager
        extend self
        CONTEXT_BAGGAGE_KEY = OpenTelemetry::Baggage::Propagation::ContextKeys.span_context_key
        EMPTY_BAGGAGE = {}.freeze
        private_constant(:CONTEXT_BAGGAGE_KEY, :EMPTY_BAGGAGE)

        # Returns a new context with empty baggage
        #
        # @param [Context] context
        # @return [Context]
        def clear(context)
          context.set(CONTEXT_BAGGAGE_KEY, EMPTY_BAGGAGE)
        end

        # Returns the corresponding baggage value (or nil) for key
        #
        # @param [Context] context The context use to retrieve key
        # @param [String] key The lookup key
        # @return [Object]
        def value(context, key)
          baggage_for(context)[key]
        end

        # Returns a new context with new key-value pair
        #
        # @param [Context] context The context to update with new value
        # @param [String] key The key to store this value under
        # @param [Object] value Object to be stored under key
        # @return [Context]
        def set_value(context, key, value)
          new_baggage = baggage_for(context).dup
          new_baggage[key] = value
          context.set(CONTEXT_BAGGAGE_KEY, new_baggage)
        end

        # Returns a new context with value at key removed
        #
        # @param [Context] context The context to remove value from
        # @param [String] key The key to remove
        # @return [Context]
        def remove_value(context, key)
          baggage = baggage_for(context)
          return context unless baggage.key?(key)

          new_baggage = baggage.dup
          new_baggage.delete(key)
          context.set(CONTEXT_BAGGAGE_KEY, new_baggage)
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

        def baggage_for(context)
          context.get(CONTEXT_BAGGAGE_KEY) || EMPTY_BAGGAGE
        end
      end
    end
  end
end
