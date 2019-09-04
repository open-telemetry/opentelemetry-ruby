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

      # Returns a new link.
      #
      # @param [SpanContext] span_context The context of the linked {Span}.
      # @param [optional Hash<String, Object>] attributes A hash of attributes
      #   for this link. Attributes will be frozen during Link initialization.
      #   If both attributes and a link_formatter are provided, an ArgumentError
      #   will be raised.
      # @yieldreturn [optional Hash<String, Object>] attribute_formatter A
      #   callable that returns a hash of attributes for this link. Will be
      #   called lazily and its return value will be frozen when attributes are
      #   first accessed. If both attributes and a link_formatter are provided,
      #   an ArgumentError will be raised.
      # @return [Link]
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(span_context:, attributes: nil, &attribute_formatter)
        raise ArgumentError unless span_context.instance_of?(SpanContext)
        raise ArgumentError unless attributes.nil? || attributes.is_a?(Hash)
        raise ArgumentError unless attributes.nil? || Internal.valid_attributes?(attributes)
        raise ArgumentError, 'Expected attributes or block, but received both' if attributes && attribute_formatter

        @context = span_context

        if attribute_formatter
          @attributes = nil
          @attribute_formatter = attribute_formatter
        else
          @attributes = attributes.freeze || EMPTY_ATTRIBUTES
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Returns the attributes for this link. If an attribute_formatter was
      # was provided when creating the link, it will be called lazily when
      # attributes are first accessed.
      #
      # @return [Hash<String, Object>]
      def attributes
        if @attributes
          @attributes
        else
          attributes = @attribute_formatter.call
          raise 'Attribute formatter returned invalid attributes' unless Internal.valid_attributes?(attributes)

          @attributes = attributes.freeze
        end
      end
    end
  end
end
