# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::Status do
  describe '.canonical_code' do
    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.new(0)
      status.canonical_code.must_equal(0)
    end
  end

  describe '.description' do
    it 'is an empty string by default' do
      status = OpenTelemetry::Trace::Status.new(0)
      status.description.must_equal('')
    end

    it 'reflects the value passed in' do
      status = OpenTelemetry::Trace::Status.new(0, description: 'ok')
      status.description.must_equal('ok')
    end
  end

  describe '.initialize' do
    it 'initializes a Status with required arguments' do
      status = OpenTelemetry::Trace::Status.new(0, description: 'this is ok')
      status.canonical_code.must_equal(0)
      status.description.must_equal('this is ok')
    end

    it 'checks canonical_code for type' do
      proc do
        OpenTelemetry::Trace::Status.new(:OK)
      end.must_raise(ArgumentError)
    end

    it 'checks description for type' do
      proc do
        OpenTelemetry::Trace::Status.new(0, description: :ok)
      end.must_raise(ArgumentError)
    end
  end

  describe '.ok?' do
    it 'reflects canonical_code when OK' do
      ok = OpenTelemetry::Trace::Status::OK
      status = OpenTelemetry::Trace::Status.new(ok)
      status.ok?.must_equal(true)
    end

    it 'reflects canonical_code when not OK' do
      canonical_codes = OpenTelemetry::Trace::Status.constants - %i[OK]
      canonical_codes.each do |canonical_code|
        code = OpenTelemetry::Trace::Status.const_get(canonical_code)
        status = OpenTelemetry::Trace::Status.new(code)
        status.ok?.must_equal(false)
      end
    end
  end
end
