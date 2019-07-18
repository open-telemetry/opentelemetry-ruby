# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::SpanId do
  describe '::INVALID' do
    it 'returns invalid SpanId' do
      OpenTelemetry::Trace::SpanId::INVALID.must_equal(
        OpenTelemetry::Trace::SpanId.new(0)
      )
    end
  end

  describe '.generate' do
    it 'returns a new span id' do
      span_id = OpenTelemetry::Trace::SpanId.generate
      span_id.must_be_instance_of(OpenTelemetry::Trace::SpanId)
    end

    it 'returns a valid span id' do
      span_id = OpenTelemetry::Trace::SpanId.generate
      span_id.valid?.must_equal(true)
    end
  end

  describe '#valid?' do
    it 'returns true when valid span id' do
      span_id = OpenTelemetry::Trace::SpanId.new(1)
      span_id.valid?.must_equal(true)
    end

    it 'returns false when invalid span id' do
      span_id = OpenTelemetry::Trace::SpanId.new(0)
      span_id.valid?.must_equal(false)
    end
  end

  describe '#==' do
    it 'returns true when two span ids have the same values' do
      span1_id = OpenTelemetry::Trace::SpanId.new(1)
      span2_id = OpenTelemetry::Trace::SpanId.new(1)
      span1_id.must_equal(span2_id)
    end

    it 'returns false when two span ids have different values' do
      span1_id = OpenTelemetry::Trace::SpanId.new(1)
      span2_id = OpenTelemetry::Trace::SpanId.new(2)
      span1_id.wont_equal(span2_id)
    end
  end

  describe '#to_lower_base16' do
    it 'returns all zeros for invalid span id' do
      span_id = OpenTelemetry::Trace::SpanId::INVALID
      span_id.to_lower_base16.must_equal('0000000000000000')
    end

    it 'returns base16 representation of the span id' do
      span_id = OpenTelemetry::Trace::SpanId.new((1 << 64) - 1)
      span_id.to_lower_base16.must_equal('ffffffffffffffff')
    end
  end
end
