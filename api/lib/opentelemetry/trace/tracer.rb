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

      private_constant(:CONTEXT_SPAN_KEY, :HTTP_TEXT_FORMAT, :BINARY_FORMAT)

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

      def binary_format
        BINARY_FORMAT
      end

      def http_text_format
        HTTP_TEXT_FORMAT
      end
    end
  end
end
