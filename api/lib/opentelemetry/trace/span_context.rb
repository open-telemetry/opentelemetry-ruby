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
        trace_id: generate_trace_id,
        span_id: generate_span_id,
        trace_flags: TraceFlags::DEFAULT
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_flags = trace_flags
      end

      def valid?
        !(@trace_id.zero? || @span_id.zero?)
      end

      private

      SPAN_ID_RANGE = (1..(2**64 - 1)).freeze
      TRACE_ID_RANGE = (1..(2**128 - 1)).freeze

      private_constant(:SPAN_ID_RANGE, :TRACE_ID_RANGE)

      def generate_trace_id
        rand(TRACE_ID_RANGE)
      end

      def generate_span_id
        rand(SPAN_ID_RANGE)
      end
    end
  end
end
