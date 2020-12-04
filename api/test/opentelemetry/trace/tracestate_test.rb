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
    it 'will not exceed 32 members' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash(31.times.collect { |n| [n.to_s, n.to_s] }.to_h)
      tracestate = tracestate.set_value('a', 'a').set_value('b', 'b')
      _(tracestate.to_h.size).must_be :<=, 32
    end
    it 'returns a new Tracestate' do
      old_tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a')
      new_tracestate = old_tracestate.set_value('a', 'b')
      _(new_tracestate).wont_equal old_tracestate
    end
    it 'adds a new key-value pair' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a')
      tracestate = tracestate.set_value('b', 'b')
      _(tracestate.to_h).must_equal('a' => 'a', 'b' => 'b')
    end
    it 'updates the value for an existing key' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a')
      tracestate = tracestate.set_value('a', 'b')
      _(tracestate.to_h).must_equal('a' => 'b')
    end
  end

  describe '#delete' do
    it 'returns a new Tracestate' do
    end
    it 'deletes the specified key' do
    end
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
