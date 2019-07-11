# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext contains the state that must propagate to child @see Spans and across process boundaries.
    # It contains the identifiers (a @see TraceId and @see SpanId) associated with the @see Span and a set of
    # @see TraceOptions.
    #
    # Design note: MRI optimizes storage of objects with 3 or fewer member variables, inlining the fields into the
    # RVALUE. To take advantage of this, we avoid initializing @tracestate if undefined.
    class SpanContext
      attr_reader :trace_id, :span_id, :trace_options

      def initialize(
        trace_id: generate_trace_id,
        span_id: generate_span_id,
        trace_options: TraceOptions::DEFAULT,
        tracestate: nil
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_options = trace_options
        @tracestate = tracestate if tracestate
      end

      def tracestate
        @tracestate || Tracestate::DEFAULT
      end

      def valid?
        !(@trace_id.zero? || @span_id.zero?)
      end
    end
  end
end
