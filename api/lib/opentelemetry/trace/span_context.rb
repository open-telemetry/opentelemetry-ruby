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

      INVALID_TRACE_ID = '0' * 32
      INVALID_SPAN_ID = '0' * 16

      private_constant(:INVALID_TRACE_ID, :INVALID_SPAN_ID)

      def generate_trace_id
        loop do
          id = Random::DEFAULT.bytes(16).unpack1('H*')
          return id unless id == INVALID_TRACE_ID
        end
      end

      def generate_span_id
        loop do
          id = Random::DEFAULT.bytes(8).unpack1('H*')
          return id unless id == INVALID_SPAN_ID
        end
      end
    end
  end
end
