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
        Context.get(CONTEXT_SPAN_KEY) || Span.INVALID
      end

      # TODO: This is a helper for the default use-case of extending the current trace with a span.
      #
      # The spec-ed API seems a little clunky. Default use-case looks like:
      # OpenTelemetry.tracer.with_span(OpenTelemetry.tracer.start_span('do-the-thing')) do ... end
      #
      # OpenTracing equivalent looks like:
      # OpenTracing.start_active_span('do-the-thing') do ... end
      #
      # OpenCensus equivalent looks like:
      # OpenCensus::Trace.in_span('do-the-thing') do ... end
      #
      # With this helper:
      # OpenTelemetry.tracer.in_span('do-the-thing') do ... end
      def in_span(name, attributes: nil, links: nil, events: nil, start_timestamp: nil, kind: nil)
        span = start_span(name, attributes: attributes, links: links, events: events, start_timestamp: start_timestamp, kind: kind)
        with_span(span) { |s| yield s }
      end

      def with_span(span)
        Context.with(CONTEXT_SPAN_KEY, span) { |s| yield s }
      end

      def start_root_span(name, attributes: nil, links: nil, events: nil, start_timestamp: nil, kind: nil)
        raise ArgumentError if name.nil?

        Span.new
      end

      def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, events: nil, start_timestamp: nil, kind: nil)
        raise ArgumentError if name.nil?

        span_context = with_parent&.context || with_parent_context || current_span.context
        if span_context.valid?
          Span.new(span_context: span_context)
        else
          Span.new
        end
      end

      # Returns a new Event. This should be called by an EventFormatter, a
      # lazily evaluated callable that returns an Event that is passed to
      # {Span#add_event}, or to pass Events to {Tracer#in_span},
      # {Tracer#start_span} or {Tracer#start_root_span}.
      #
      # Example use:
      #
      #   span = tracer.in_span('op', events: [tracer.create_event('e1')])
      #   span.add_event { tracer.create_event('e2', {'a' => 3}) }
      #
      # @param [String] name The name of the event.
      # @param [optional Hash<String, Object>] attrs One or more key:value
      #   pairs, where the keys must be strings and the values may be string,
      #   boolean or numeric type.
      # @param [optional Time] timestamp Optional timestamp for the event.
      # @return a new Event.
      def create_event(name, attrs = nil, timestamp: nil)
        raise ArgumentError unless name.is_a?(String)
        raise ArgumentError unless Internal.valid_attributes?(attrs)

        EVENT_OR_LINK
      end

      # Returns a new Link. This should be called by a LinkFormatter, a
      # lazily evaluated callable that returns a Link that is passed to
      # {Span#add_link}, or to pass Links to {Tracer#in_span},
      # {Tracer#start_span} or {Tracer#start_root_span}.
      #
      # Example use:
      #
      #   span = tracer.in_span('op', links: [tracer.create_link(SpanContext.new)])
      #   span.add_link { tracer.create_link(SpanContext.new, {'a' => 3}) }
      #
      # @param [SpanContext] span_context The context of the linked {Span}.
      # @param [optional Hash<String, Object>] attrs A hash of attributes
      #   for this link. Attributes will be frozen during Link initialization.
      # @return a new Link
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
