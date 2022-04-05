# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    # ClassScopedAttributes contains common helpers for attribute propagation
    # Various classes should extend this module to get `with_attributes`
    # functionality scoped to that class.
    module ClassScopedAttributes
      extend self

      def current_attributes_hash
        @current_attributes_hash ||= Context.create_key("#{self.name}-current-attributes-hash")
      end

      # Returns the attributes hash found in the optional context or the
      # current context if none is provided.
      #
      # @param [optional Context] context The context to lookup the current
      #   attributes hash. Defaults to Context.current
      def attributes(context = nil)
        context ||= Context.current
        context.value(current_attributes_hash) || {}
      end

      # Returns a context containing the merged attributes hash, derived from the
      # optional parent context, or the current context if one was not provided.
      #
      # @param [optional Context] context The context to use as the parent for
      #   the returned context
      def context_with_attributes(attributes_hash, parent_context: Context.current)
        attributes_hash = attributes(parent_context).merge(attributes_hash)
        parent_context.set_value(current_attributes_hash, attributes_hash)
      end

      # Activates/deactivates the merged attributes hash within the current Context,
      # which makes the "current attributes hash" available implicitly.
      #
      # On exit, the attributes hash that was active before calling this method
      # will be reactivated.
      #
      # @param [Hash] attributes_hash attributes to merge into the current attributes hash
      # @yield [Hash, Context] yields attributes hash and a context containing the
      #   attributes hash to the block.
      def with_attributes(attributes_hash)
        attributes_hash = attributes.merge(attributes_hash)
        Context.with_value(current_attributes_hash, attributes_hash) { |c, h| yield h, c }
      end
    end
  end
end
