# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::TraceFlags do
  describe '.new' do
    it 'is private' do
      _(-> { OpenTelemetry::Trace::TraceFlags.new(0) })\
        .must_raise(NoMethodError)
    end
  end
  describe '.from_byte' do
    it 'can be initialized with a byte' do
      flags = OpenTelemetry::Trace::TraceFlags.from_byte(0)
      _(flags.sampled?).must_equal(false)
    end

    it 'defaults if flags is not an 8-bit byte' do
      flags = OpenTelemetry::Trace::TraceFlags.from_byte(256)
      _(flags.sampled?).must_equal(false)
    end
  end

  describe '#sampled?' do
    it 'reflects the least-significant bit in the flags' do
      sampled = OpenTelemetry::Trace::TraceFlags.from_byte(1)
      not_sampled = OpenTelemetry::Trace::TraceFlags.from_byte(0)

      _(sampled.sampled?).must_equal(true)
      _(not_sampled.sampled?).must_equal(false)
    end
  end
end
