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
        CONTEXT_BAGGAGE_KEY = '__baggage__'
        EMPTY_BAGGAGE = {}.freeze
        private_constant(:CONTEXT_BAGGAGE_KEY, :EMPTY_BAGGAGE)

        # Executes block with the specified baggage. Restores previous baggage
        # after executing the block.
        #
        # @param [String] key The lookup key
        # @param [Callable] blk The block to execute
        def with(baggage)
          ctx = context.set(CONTEXT_BAGGAGE_KEY, baggage)
          prev = ctx.attach
          yield
        ensure
          ctx.detach(prev)
        end

        # Executes block in a context with baggage cleared
        #
        # @blk [Callable] blk Block to execute
        def clear(&blk)
          with(EMPTY_BAGGAGE, &blk)
        end

        # Returns the corresponding baggage value (or nil) for key
        #
        # @param [String] key The lookup key
        # @return [Object]
        def value(key)
          current_baggage[key]
        end

        # Executes block in a newly attached Context with updated baggage containing
        # key and value. Restores previous baggage after executing the block.
        #
        # @param [String] key The key to store this value under
        # @param [Object] value Object to be stored under key
        # @param [Callable] blk Block to execute
        def set_value(key, value, &blk)
          new_baggage = current_baggage.dup
          new_baggage[key] = value
          with(new_baggage, &blk)
        end

        # Executes block in a newly attached Context with updated baggage with
        # key removed. Restores previous baggage after executing the block.
        #
        # @param [String] key The key to remove
        # @param [Callable] blk Block to execute
        def remove_value(key, &blk)
          new_baggage = current_baggage.dup
          new_baggage.delete(key)
          with(new_baggage, &blk)
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

        def current_baggage
          context.get(CONTEXT_BAGGAGE_KEY) || EMPTY_BAGGAGE
        end

        def context
          Context.current
        end
      end
    end
  end
end
