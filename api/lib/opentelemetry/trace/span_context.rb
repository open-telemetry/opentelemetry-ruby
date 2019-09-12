# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext contains the state that must propagate to child {Span}s and across process boundaries.
    # It contains the identifiers (a trace ID and span ID) associated with the {Span}, a set of
    # {TraceFlags}, and a boolean indicating that the SpanContext was extracted from the wire.
    class SpanContext
      attr_reader :trace_id, :span_id, :trace_flags, :remote

      # Returns a new {SpanContext}.
      #
      # @param [optional String] trace_id The trace ID associated with a {Span}.
      # @param [optional String] span_id The span ID associated with a {Span}.
      # @param [optional TraceFlags] trace_flags The trace flags associated with a {Span}.
      # @param [optional Boolean] remote Whether the {SpanContext} was extracted from the wire.
      # @return [SpanContext]
      def initialize(
        trace_id: Trace.generate_trace_id,
        span_id: Trace.generate_span_id,
        trace_flags: TraceFlags::DEFAULT,
        remote: false
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_flags = trace_flags
        @remote = remote
      end

      # Returns true if the {SpanContext} has a non-zero trace ID and non-zero span ID.
      #
      # @return [Boolean]
      def valid?
        @trace_id != INVALID_TRACE_ID && @span_id != INVALID_SPAN_ID
      end

      # Returns true if the {SpanContext} was propagated from a remote parent.
      #
      # @return [Boolean]
      alias remote? remote

      # Represents an invalid {SpanContext}, with an invalid trace ID and an invalid span ID.
      INVALID = new(trace_id: INVALID_TRACE_ID, span_id: INVALID_SPAN_ID)
    end
  end
end
