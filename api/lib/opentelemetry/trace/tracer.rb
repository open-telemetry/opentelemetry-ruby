# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of Tracer.
    class Tracer
      CONTEXT_SPAN_KEY = :__span__
      HTTP_TEXT_FORMAT = nil # TODO: implement HttpTraceContext

      # Formatter for serializing and deserializing a SpanContext into a binary format.
      module NoopBinaryFormat
        extend self

        def to_bytes(span_context)
          raise ArgumentError if span_context.nil?

          []
        end

        def from_bytes(bytes)
          raise ArgumentError if bytes.nil?

          SpanContext.INVALID
        end
      end

      private_constant(:CONTEXT_SPAN_KEY, :HTTP_TEXT_FORMAT, :NoopBinaryFormat)

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
      def in_span(name, sampler: nil, links: nil, recording_events: nil, kind: nil)
        span = start_span(name, sampler: sampler, links: links, recording_events: recording_events, kind: kind)
        with_span(span) { |s| yield s }
      end

      def with_span(span)
        Context.with(CONTEXT_SPAN_KEY, span) { |s| yield s }
      end

      def start_root_span(name, sampler: nil, links: nil, recording_events: nil, kind: nil)
        raise ArgumentError if name.nil?

        Span.create_random
      end

      def start_span(name, with_parent: nil, with_parent_context: nil, sampler: nil, links: nil, recording_events: nil, kind: nil)
        raise ArgumentError if name.nil?

        span_context = with_parent&.context || with_parent_context || current_span.context
        if SpanContext.INVALID == span_context
          Span.create_random
        else
          Span.new(span_context)
        end
      end

      def record_span_data(span_data)
        raise ArgumentError if span_data.nil?
      end

      def binary_format
        NoopBinaryFormat
      end

      def http_text_format
        HTTP_TEXT_FORMAT
      end
    end
  end
end
