# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # A link to a {Span}. Used (for example) in batching operations, where a
      # single batch handler processes multiple requests from different traces.
      # A Link can be also used to reference spans from the same trace. A Link
      # and its attributes are immutable.
      class Link
        EMPTY_ATTRIBUTES = {}.freeze

        private_constant :EMPTY_ATTRIBUTES

        # Returns the {OpenTelemetry::Trace::SpanContext} for this link
        #
        # @return [SpanContext]
        attr_reader :context

        # Returns the attributes for this link.
        #
        # @return [Hash<String, Object>]
        attr_reader :attributes

        # @api private
        # Returns a new link.
        #
        # @param [SpanContext] span_context The context of the linked {Span}.
        # @param [Hash<String, Object>] attributes A hash of attributes for
        #   this link. Attributes will be frozen during Link initialization.
        # @return [Link]
        def initialize(span_context:, attributes:)
          @context = span_context
          @attributes = attributes.freeze || EMPTY_ATTRIBUTES
        end
      end
    end
  end
end
