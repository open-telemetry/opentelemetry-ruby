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
        trace_options: TraceOptions::DEFAULT,
        tracestate: nil
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_options = trace_options

        # Design note: MRI optimizes storage of objects with 3 or fewer member variables, inlining the fields into the
        # RVALUE. To take advantage of this, we can avoid initializing @tracestate if undefined.
        @tracestate = tracestate # TODO: if tracestate
      end

      def tracestate
        @tracestate # TODO: || Tracestate::DEFAULT
      end

      def valid?
        @trace_id.nonzero? && @span_id.nonzero?
      end
    end
  end
end
