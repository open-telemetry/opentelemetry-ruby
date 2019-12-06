# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/propagation'

module OpenTelemetry
  # Manages context on a per-thread basis
  class Context
    KEY = :__opentelemetry_context__
    EMPTY_ENTRIES = {}.freeze

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
      def with_current(ctx)
        prev = ctx.attach
        yield
      ensure
        ctx.detach(prev)
      end

      # Execute a block in a new context with key set to value. Restores the
      # previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Object] value The object stored under key
      # @param [Callable] blk The block to execute in a new context
      def with_value(key, value, &blk)
        ctx = current.set_value(key, value)
        prev = ctx.attach
        yield value
      ensure
        ctx.detach(prev)
      end

      # Execute a block in a new context where its values are merged with the
      # incoming values. Restores the previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Hash] values Will be merged with values of the current context
      #  and returned in a new context
      #
      # @param [Callable] blk The block to execute in a new context
      def with_values(values, &blk)
        ctx = current.set_values(values)
        prev = ctx.attach
        yield values
      ensure
        ctx.detach(prev)
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
        new(nil, EMPTY_ENTRIES)
      end
    end

    def initialize(parent = nil, entries = {})
      @parent = parent
      @entries = entries.freeze
    end

    # Returns the corresponding value (or nil) for key
    #
    # @param [String] key The lookup key
    # @return [Object]
    def value(key)
      @entries[key]
    end

    alias [] value

    # Returns a new Context where entries contains the newly added key and value
    #
    # @param [String] key The key to store this value under
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_value(key, value)
      new_entries = @entries.dup
      new_entries[key] = value
      Context.new(self, new_entries)
    end

    # Returns a new Context with the current context's entries merged with the
    #   new entries
    #
    # @param [Hash] values The values to be merged with the current context's
    #   entries.
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_values(values) # rubocop:disable Naming/AccessorMethodName:
      Context.new(self, @entries.merge(values))
    end

    # Makes the this context the currently active context and returns the
    # previously active context
    #
    # @return [Context]
    def attach
      prev = self.class.current
      self.class.current = self
      prev
    end

    # Detaches this context making ctx_to_attach the current context. If this
    # context is not the current context, a warning will be logged, but
    # ctx_to_attach will stil be made the current context.
    #
    # @param ctx_to_attach The ctx to be attached when this context is detached
    def detach(ctx_to_attach = nil)
      ctx_to_attach ||= @parent || ROOT
      if self.class.current != self
        # @todo: log warning
      end

      ctx_to_attach.attach
    end

    ROOT = empty.freeze
  end
end
