# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::Tracestate do
  describe '.new' do
    it 'is private' do
      _(-> { OpenTelemetry::Trace::Tracestate.new({}) })\
        .must_raise(NoMethodError)
    end
  end

  describe '.from_string' do
  end

  describe '.from_hash' do
  end

  describe '#value' do
    let(:tracestate) { OpenTelemetry::Trace::Tracestate.from_hash('a' => 'b') }
    it 'returns the corresponding value if it exists' do
      _(tracestate.value('a')).must_equal('b')
    end
    it 'returns nil if the key does not exist' do
      _(tracestate.value('b')).must_be_nil
    end
  end

  describe '#set_value' do
  end

  describe '#delete' do
  end

  describe '#to_s' do
  end

  describe '#empty?' do
    it 'returns true when empty' do
      _(OpenTelemetry::Trace::Tracestate.from_hash({})).must_be :empty?
    end
    it 'returns false when not empty' do
      _(OpenTelemetry::Trace::Tracestate.from_hash('a' => 'b')).wont_be :empty?
    end
  end
end
