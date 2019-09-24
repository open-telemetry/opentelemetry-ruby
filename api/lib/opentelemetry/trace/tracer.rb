# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of Tracer.
    class Tracer
      CONTEXT_SPAN_KEY = :__span__
      HTTP_TEXT_FORMAT = DistributedContext::Propagation::HTTPTextFormat.new
      BINARY_FORMAT = DistributedContext::Propagation::BinaryFormat.new
      EVENT_OR_LINK = Object.new

      private_constant(:CONTEXT_SPAN_KEY, :HTTP_TEXT_FORMAT, :BINARY_FORMAT, :EVENT_OR_LINK)

      def current_span
        Context.get(CONTEXT_SPAN_KEY) || Span::INVALID
      end

      # This is a helper for the default use-case of extending the current trace with a span.
      #
      # With this helper:
      #
      #   OpenTelemetry.tracer.in_span('do-the-thing') do ... end
      #
      # Equivalent without helper:
      #
      #   OpenTelemetry.tracer.with_span(OpenTelemetry.tracer.start_span('do-the-thing')) do ... end
      def in_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
        span = start_span(name, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind, sampling_hint: sampling_hint)
        with_span(span) { |s| yield s }
      end

      def with_span(span)
        Context.with(CONTEXT_SPAN_KEY, span) { |s| yield s }
      end

      def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
        raise ArgumentError if name.nil?

        Span.new
      end

      def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
        raise ArgumentError if name.nil?

        span_context = with_parent&.context || with_parent_context || current_span.context
        if span_context.valid?
          Span.new(span_context: span_context)
        else
          Span.new
        end
      end

      # Returns a new Event. This should be called in a block passed to {Span#add_event}.
      #
      # Example use:
      #
      #   span.add_event { tracer.create_event(name: 'e2', attributes: {'a' => 3}) }
      #
      # @param [String] name The name of the event.
      # @param [optional Hash<String, Object>] attributes One or more key:value
      #   pairs, where the keys must be strings and the values may be string,
      #   boolean or numeric type.
      # @param [optional Time] timestamp Optional timestamp for the event.
      # @return a new Event.
      def create_event(name:, attributes: nil, timestamp: nil)
        raise ArgumentError unless name.is_a?(String)
        raise ArgumentError unless Internal.valid_attributes?(attributes)

        EVENT_OR_LINK
      end

      # Returns a new Link. This should be called to pass Links to {Tracer#in_span},
      # {Tracer#start_span} or {Tracer#start_root_span}.
      #
      # Example use:
      #
      #   span = tracer.in_span('op', links: [tracer.create_link(SpanContext.new)])
      #
      # @param [SpanContext] span_context The context of the linked {Span}.
      # @param [optional Hash<String, Object>] attrs A hash of attributes
      #   for this link. Attributes will be frozen during Link initialization.
      # @return [Link]
      def create_link(span_context, attrs = nil)
        raise ArgumentError unless span_context.instance_of?(SpanContext)
        raise ArgumentError unless Internal.valid_attributes?(attrs)

        EVENT_OR_LINK
      end

      def binary_format
        BINARY_FORMAT
      end

      def http_text_format
        HTTP_TEXT_FORMAT
      end
    end
  end
end
