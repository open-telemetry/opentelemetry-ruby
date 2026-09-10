# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::SpanContext do
  let(:span_context) { OpenTelemetry::Trace::SpanContext.new }
  let(:invalid_context) { OpenTelemetry::Trace::SpanContext::INVALID }

  describe '#initialize' do
    it 'must generate valid span_id and trace_id by default' do
      _(span_context.trace_id).wont_equal(OpenTelemetry::Trace::INVALID_TRACE_ID)
      _(span_context.span_id).wont_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
    end
  end

  describe '#valid?' do
    it 'is true by default' do
      _(span_context).must_be(:valid?)
    end

    it 'is false for invalid context' do
      _(invalid_context).wont_be(:valid?)
    end
  end

  describe '#remote?' do
    it 'is false by default' do
      _(span_context).wont_be(:remote?)
    end

    it 'reflects the value passed in' do
      context = OpenTelemetry::Trace::SpanContext.new(remote: true)
      _(context).must_be(:remote?)
    end
  end

  describe '#trace_id' do
    it 'reflects the value passed in' do
      trace_id = OpenTelemetry::Trace.generate_trace_id
      context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id)
      _(context.trace_id).must_equal(trace_id)
    end

    it 'is invalid for invalid context' do
      _(invalid_context.trace_id)
        .must_equal(OpenTelemetry::Trace::INVALID_TRACE_ID)
    end
  end

  describe '#span_id' do
    it 'reflects the value passed in' do
      span_id = OpenTelemetry::Trace.generate_span_id
      context = OpenTelemetry::Trace::SpanContext.new(span_id: span_id)
      _(context.span_id).must_equal(span_id)
    end

    it 'is invalid for invalid context' do
      _(invalid_context.span_id).must_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
    end
  end

  describe '#trace_flags' do
    it 'is unsampled by default' do
      _(span_context.trace_flags).wont_be(:sampled?)
    end

    it 'reflects the value passed in' do
      flags = OpenTelemetry::Trace::TraceFlags.from_byte(1)
      context = OpenTelemetry::Trace::SpanContext.new(trace_flags: flags)
      _(context.trace_flags).must_equal(flags)
    end
  end
end
