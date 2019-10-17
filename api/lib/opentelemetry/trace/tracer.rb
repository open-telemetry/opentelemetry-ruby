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
        Span.new
      end

      def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
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
