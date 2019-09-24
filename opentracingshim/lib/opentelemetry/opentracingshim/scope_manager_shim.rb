# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    # A ScopeManagerShim provides an API for interfacing with
    # OpenTelemetry Tracers and Spans as OpenTracing objects
    class ScopeManagerShim
      def initialize(tracer)
        @tracer = tracer
      end

      # Activate the given span
      #
      # @param [Span] span An OpenTelemetrySpan
      # @return [SpanShim]
      def activate(span, finish_on_close: true)
        SpanShim.new(@tracer.with_span(span))
      end

      # Get the active span as a SpanShim
      #
      # @return [SpanShim]
      def active
        SpanShim.new(@tracer.current_span)
      end
    end
  end
end
