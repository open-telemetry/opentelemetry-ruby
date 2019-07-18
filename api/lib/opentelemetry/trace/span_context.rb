# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext represents the portion of a {Span} which must be serialized
    # and propagated along side of a distributed context. SpanContexts are
    # immutable. SpanContext MUST be a final (sealed) class.
    #
    # The OpenTelemetry SpanContext representation conforms to the w3c
    # TraceContext {https://www.w3.org/TR/trace-context/ specification}. It
    # contains two identifiers - a trace id and a span id - along with a set of
    # common trace options and system-specific TraceState values. SpanContext
    # is represented as an interface, in order to be serializable into a wider
    # variety of trace context wire formats.
    class SpanContext
      # Returns the trace identifier
      #
      # @return [TraceId]
      attr_reader :trace_id

      # Returns the span identifier
      #
      # @return [SpanId]
      attr_reader :span_id

      attr_reader :trace_options, :tracestate

      def initialize(
        trace_id: TraceId.generate,
        span_id: SpanId.generate,
        trace_options: nil, # Use TraceOptions::DEFAULT when added to API
        tracestate: nil
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_options = trace_options

        # Design note: MRI optimizes storage of objects with 3 or fewer member variables, inlining the fields into the
        # RVALUE. To take advantage of this, we can avoid initializing @tracestate if undefined.
        @tracestate = tracestate # TODO: if tracestate
      end

      # TODO: optimization
      # def tracestate
      #   @tracestate || Tracestate::DEFAULT
      # end

      # Checks if the SpanContext is valid
      #
      # A valid SpanContext has a valid {TraceId} and a valid {SpanId}.
      #
      # @return [Boolean] true if the span context is valid
      def valid?
        @trace_id.valid? && @span_id.valid?
      end
    end
  end
end
