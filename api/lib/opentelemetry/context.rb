# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

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

      def empty
        new(nil, EMPTY_ENTRIES)
      end

      # def with_context
      #   parent_ctx = current
      #   child_ctx = Context.new(parent_ctx)
      #   self.current = child_ctx
      #   yield(child_ctx)
      # ensure
      #   self.current = parent_ctx
      # end
    end

    def initialize(parent = nil, entries = {})
      @parent = parent
      @entries = entries
    end

    # Returns the corresponding value (or nil) for key
    #
    # @param [String] key The lookup key
    # @return [Object]
    def get(key)
      @entries[key]
    end

    # Returns a new Context where entries contains the newly added key and value
    #
    # @param [String] key The key to store this value under
    # @param [Object] value Object to be stored under key
    def set(key, value)
      new_entries = @entries.dup
      new_entries[key] = value
      Context.new(self, new_entries)
    end

    ROOT = empty.freeze
  end
end
