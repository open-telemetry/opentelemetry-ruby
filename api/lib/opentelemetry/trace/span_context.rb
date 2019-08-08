# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext contains the state that must propagate to child @see Spans and across process boundaries.
    # It contains the identifiers (a @see TraceId and @see SpanId) associated with the @see Span and a set of
    # @see TraceOptions.
    class SpanContext
      attr_reader :trace_id, :span_id, :trace_options

      def initialize(
        trace_id: generate_trace_id,
        span_id: generate_span_id,
        trace_options: TraceOptions::DEFAULT
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_options = trace_options
      end

      def valid?
        !(@trace_id.zero? || @span_id.zero?)
      end
    end
  end
end
