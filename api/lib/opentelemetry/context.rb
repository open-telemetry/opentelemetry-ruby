# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/key'
require 'opentelemetry/context/propagation'

module OpenTelemetry
  # Manages context on a per-fiber basis
  class Context
    KEY = :__opentelemetry_context__
    EMPTY_ENTRIES = {}.freeze

    class << self
      # Returns a key used to index a value in a Context
      #
      # @param [String] name The key name
      # @return [Context::Key]
      def create_key(name)
        Key.new(name)
      end

      # Returns current context, which is never nil
      #
      # @return [Context]
      def current
        Thread.current[KEY] ||= ROOT
      end

      # @api private
      def current=(ctx)
        Thread.current[KEY] = ctx
      end

      # Returns the previous context so that it can be restored
      #
      # @param [Context] context The new context
      # @return [Context] prev The previous context
      def attach(context)
        return current.parent if context == current

        prev = current
        self.current = context
        context.parent = prev
      end

      # Restores the current context to the context supplied or the parent context
      # if no context is provided
      #
      # @param [Context] previous_context The previous context to restore
      def detach(previous_context = nil)
        OpenTelemetry.logger.warn 'Calls to detach should match corresponding calls to attach' if current.parent != previous_context

        previous_context ||= current.parent || ROOT
        self.current = previous_context
      end

      # Executes a block with ctx as the current context. It restores
      # the previous context upon exiting.
      #
      # @param [Context] ctx The context to be made active
      # @yield [context] Yields context to the block
      def with_current(ctx)
        prev = attach(ctx)
        yield ctx
      ensure
        detach(prev)
      end

      # Execute a block in a new context with key set to value. Restores the
      # previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Object] value The object stored under key
      # @param [Callable] Block to execute in a new context
      # @yield [context, value] Yields the newly created context and value to
      #   the block
      def with_value(key, value)
        ctx = current.set_value(key, value)
        prev = attach(ctx)
        yield ctx, value
      ensure
        detach(prev)
      end

      # Execute a block in a new context where its values are merged with the
      # incoming values. Restores the previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Hash] values Will be merged with values of the current context
      #  and returned in a new context
      # @param [Callable] Block to execute in a new context
      # @yield [context, values] Yields the newly created context and values
      #   to the block
      def with_values(values)
        ctx = current.set_values(values)
        prev = attach(ctx)
        yield ctx, values
      ensure
        detach(prev)
      end

      def clear
        self.current = ROOT
      end

      def empty
        new(EMPTY_ENTRIES)
      end
    end

    attr_accessor :parent

    def initialize(entries)
      @entries = entries.freeze
      @parent = parent
    end

    # Returns the corresponding value (or nil) for key
    #
    # @param [Key] key The lookup key
    # @return [Object]
    def value(key)
      @entries[key]
    end

    alias [] value

    # Returns a new Context where entries contains the newly added key and value
    #
    # @param [Key] key The key to store this value under
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_value(key, value)
      new_entries = @entries.dup
      new_entries[key] = value
      Context.new(new_entries)
    end

    # Returns a new Context with the current context's entries merged with the
    #   new entries
    #
    # @param [Hash] values The values to be merged with the current context's
    #   entries.
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_values(values) # rubocop:disable Naming/AccessorMethodName:
      Context.new(@entries.merge(values))
    end

    ROOT = empty.freeze
  end
end
