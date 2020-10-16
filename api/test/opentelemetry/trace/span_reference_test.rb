# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::SpanReference do
  let(:span_reference) { OpenTelemetry::Trace::SpanReference.new }
  let(:invalid_reference) { OpenTelemetry::Trace::SpanReference::INVALID }

  describe '#initialize' do
    it 'must generate valid span_id and trace_id by default' do
      _(span_reference.trace_id).wont_equal(OpenTelemetry::Trace::INVALID_TRACE_ID)
      _(span_reference.span_id).wont_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
    end
  end

  describe '#valid?' do
    it 'is true by default' do
      _(span_reference).must_be(:valid?)
    end

    it 'is false for invalid reference' do
      _(invalid_reference).wont_be(:valid?)
    end
  end

  describe '#remote?' do
    it 'is false by default' do
      _(span_reference).wont_be(:remote?)
    end

    it 'reflects the value passed in' do
      reference = OpenTelemetry::Trace::SpanReference.new(remote: true)
      _(reference).must_be(:remote?)
    end
  end

  describe '#trace_id' do
    it 'reflects the value passed in' do
      trace_id = OpenTelemetry::Trace.generate_trace_id
      reference = OpenTelemetry::Trace::SpanReference.new(trace_id: trace_id)
      _(reference.trace_id).must_equal(trace_id)
    end

    it 'is invalid for invalid reference' do
      _(invalid_reference.trace_id)
        .must_equal(OpenTelemetry::Trace::INVALID_TRACE_ID)
    end
  end

  describe '#span_id' do
    it 'reflects the value passed in' do
      span_id = OpenTelemetry::Trace.generate_span_id
      reference = OpenTelemetry::Trace::SpanReference.new(span_id: span_id)
      _(reference.span_id).must_equal(span_id)
    end

    it 'is invalid for invalid reference' do
      _(invalid_reference.span_id).must_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
    end
  end

  describe '#trace_flags' do
    it 'is unsampled by default' do
      _(span_reference.trace_flags).wont_be(:sampled?)
    end

    it 'reflects the value passed in' do
      flags = OpenTelemetry::Trace::TraceFlags.from_byte(1)
      reference = OpenTelemetry::Trace::SpanReference.new(trace_flags: flags)
      _(reference.trace_flags).must_equal(flags)
    end
  end
end
