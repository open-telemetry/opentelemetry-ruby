# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/propagation'

module OpenTelemetry
  # Manages context on a per-thread basis
  class Context
    KEY = :__opentelemetry_context__

    class << self
      # Returns current context, which is never nil
      #
      # @return [Context]
      def current
        Thread.current[KEY] ||= ROOT
      end

      # Sets the current context
      #
      # @param [Context] ctx The context to be made active
      def current=(ctx)
        Thread.current[KEY] = ctx
      end

      # Executes a block with ctx as the current context. It restores
      # the previous context upon exiting.
      #
      # @param [Context] ctx The context to be made active
      # @param [Callable] blk Block to execute in a new context
      def with_current(ctx, &blk)
        attach(ctx, &blk)
      end

      # Execute a block in a new context with key set to value. Restores the
      # previous context after the block executes.
      #
      # @param [String] key The lookup key
      # @param [Object] value The object stored under key
      # @param [Callable] blk Block to execute in a new context
      def with_value(key, value, &blk)
        ctx = current.set_value(key, value)
        attach(ctx, value, &blk)
      end

      # Execute a block in a new context where its values are merged with the
      # incoming values. Restores the previous context after the block executes.
      #
      # @param [String] key The lookup key
      # @param [Hash] values Will be merged with values of the current context
      #  and returned in a new context
      # @param [Callable] blk Block to execute in a new context
      def with_values(values, &blk)
        ctx = current.set_values(values)
        attach(ctx, values, &blk)
      end

      # Returns the value associated with key in the current context
      #
      # @param [String] key The lookup key
      def value(key)
        current.value(key)
      end

      def clear
        self.current = ROOT
      end

      def empty
        new(nil, nil, nil)
      end

      private

      def attach(ctx, yield_value = nil, &blk)
        prev = current
        self.current = ctx
        yield_value.nil? ? blk.call : blk.call(yield_value)
      ensure
        self.current = prev
      end
    end

    def initialize(parent, key, value)
      @parent = parent
      @key = key
      @value = value
    end

    # Returns the corresponding value (or nil) for key
    #
    # @param [String] key The lookup key
    # @return [Object]
    def value(key)
      if key == @key
        @value
      elsif @parent
        @parent.value(key)
      end
    end

    alias [] value

    # Returns a new Context where entries contains the newly added key and value
    #
    # @param [String] key The key to store this value under
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_value(key, value)
      Context.new(self, key, value)
    end

    # Returns a new Context with the current context's entries merged with the
    #   new entries
    #
    # @param [Hash] values The values to be merged with the current context's
    #   entries.
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_values(values) # rubocop:disable Naming/AccessorMethodName:
      values.inject(self) { |parent, (k, v)| Context.new(parent, k, v) }
    end

    ROOT = empty.freeze
  end
end
