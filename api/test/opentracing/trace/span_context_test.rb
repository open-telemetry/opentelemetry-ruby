# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::SpanContext do
  describe '#trace_id' do
    it 'returns the trace id' do
      trace_id = OpenTelemetry::Trace::TraceId.generate
      span_context = build_span_context(trace_id: trace_id)
      span_context.trace_id.must_equal(trace_id)
    end
  end

  describe '#span_id' do
    it 'returns the span id' do
      span_id = OpenTelemetry::Trace::SpanId.generate
      span_context = build_span_context(span_id: span_id)
      span_context.span_id.must_equal(span_id)
    end
  end

  describe '#valid?' do
    it 'returns true when trace id and span id are valid' do
      trace_id = OpenTelemetry::Trace::TraceId.generate
      span_id = OpenTelemetry::Trace::SpanId.generate
      span_context = build_span_context(trace_id: trace_id, span_id: span_id)
      span_context.valid?.must_equal(true)
    end

    it 'returns false when trace id is invalid' do
      trace_id = OpenTelemetry::Trace::TraceId::INVALID
      span_id = OpenTelemetry::Trace::SpanId.generate
      span_context = build_span_context(trace_id: trace_id, span_id: span_id)
      span_context.valid?.must_equal(false)
    end

    it 'returns false when span id is invalid' do
      trace_id = OpenTelemetry::Trace::TraceId.generate
      span_id = OpenTelemetry::Trace::SpanId::INVALID
      span_context = build_span_context(trace_id: trace_id, span_id: span_id)
      span_context.valid?.must_equal(false)
    end
  end

  def build_span_context(*opts)
    OpenTelemetry::Trace::SpanContext.new(*opts)
  end
end
