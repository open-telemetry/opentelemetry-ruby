# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A link to a {Span}. Used (for example) in batching operations, where a
    # single batch handler processes multiple requests from different traces.
    # A Link can be also used to reference spans from the same trace. A Link
    # and its attributes are immutable.
    class Link
      EMPTY_ATTRIBUTES = {}.freeze

      # Returns the {SpanContext} for this link
      #
      # @return [SpanContext]
      attr_reader :context

      # Returns the attributes for this link
      #
      # @return [Hash<String, Object>]
      attr_reader :attributes

      # Returns a new link.
      #
      # @param [SpanContext] span_context The context of the linked {Span}.
      # @param [optional Hash<String, Object>] attributes The attributes of the {Link}.
      # @return [Link]
      def initialize(span_context:, attributes: nil)
        raise ArgumentError unless span_context.instance_of?(SpanContext)
        raise ArgumentError unless attributes.nil? || attributes.is_a?(Hash)

        @context = span_context
        @attributes = attributes || EMPTY_ATTRIBUTES
      end
    end
  end
end
