# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::TraceId do
  describe '::INVALID' do
    it 'returns invalid TraceId' do
      OpenTelemetry::Trace::TraceId::INVALID.must_equal(
        OpenTelemetry::Trace::TraceId.new(0)
      )
    end
  end

  describe '.generate' do
    it 'returns a new trace id' do
      trace_id = OpenTelemetry::Trace::TraceId.generate
      trace_id.must_be_instance_of(OpenTelemetry::Trace::TraceId)
    end

    it 'returns a valid trace id' do
      trace_id = OpenTelemetry::Trace::TraceId.generate
      trace_id.valid?.must_equal(true)
    end
  end

  describe '#valid?' do
    it 'returns true when valid trace id' do
      trace_id = OpenTelemetry::Trace::TraceId.new(1)
      trace_id.valid?.must_equal(true)
    end

    it 'returns false when invalid trace id' do
      trace_id = OpenTelemetry::Trace::TraceId.new(0)
      trace_id.valid?.must_equal(false)
    end
  end

  describe '#==' do
    it 'returns true when two trace ids have the same values' do
      trace1_id = OpenTelemetry::Trace::TraceId.new(1)
      trace2_id = OpenTelemetry::Trace::TraceId.new(1)
      trace1_id.must_equal(trace2_id)
    end

    it 'returns false when two trace ids have different values' do
      trace1_id = OpenTelemetry::Trace::TraceId.new(1)
      trace2_id = OpenTelemetry::Trace::TraceId.new(2)
      trace1_id.wont_equal(trace2_id)
    end
  end

  describe '#to_lower_base16' do
    it 'returns all zeros for invalid trace id' do
      trace_id = OpenTelemetry::Trace::TraceId::INVALID
      trace_id.to_lower_base16.must_equal('00000000000000000000000000000000')
    end

    it 'returns base16 representation of the span id' do
      trace_id = OpenTelemetry::Trace::TraceId.new((1 << 128) - 1)
      trace_id.to_lower_base16.must_equal('ffffffffffffffffffffffffffffffff')
    end
  end
end
