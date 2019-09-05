# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext contains the state that must propagate to child {Span}s and across process boundaries.
    # It contains the identifiers (a trace ID and span ID) associated with the {Span} and a set of
    # {TraceFlags}.
    class SpanContext
      attr_reader :trace_id, :span_id, :trace_flags

      def initialize(
        trace_id: Trace.generate_trace_id,
        span_id: Trace.generate_span_id,
        trace_flags: TraceFlags::DEFAULT
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_flags = trace_flags
      end

      def valid?
        @trace_id != INVALID_TRACE_ID && @span_id != INVALID_SPAN_ID
      end

      INVALID = new(trace_id: INVALID_TRACE_ID, span_id: INVALID_SPAN_ID)
    end
  end
end
