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
    it 'returns an empty Tracestate for nil' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string(nil)
      _(tracestate).must_be :empty?
    end
    it 'returns an empty Tracestate for an empty string' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('')
      _(tracestate).must_be :empty?
    end
    it 'returns an empty Tracestate for an invalid header' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('  ***=, ')
      _(tracestate).must_be :empty?
    end
    it 'omits empty members' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('a=a,,b=b')
      _(tracestate.to_h).must_equal('a' => 'a', 'b' => 'b')
    end
    it 'omits invalid keys' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('a=a,0xaa=0xaa,b=b')
      _(tracestate.to_h).must_equal('a' => 'a', 'b' => 'b')
    end
    it 'omits invalid values' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('a=a,key==,,b=b')
      _(tracestate.to_h).must_equal('a' => 'a', 'b' => 'b')
    end
    it 'omits keys containing whitespace' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('a=a,ke y=value,b=b')
      _(tracestate.to_h).must_equal('a' => 'a', 'b' => 'b')
    end
    it 'strips surrounding whitespace from members' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('  a=a  ')
      _(tracestate.to_h).must_equal('a' => 'a')
    end
    it 'preserves whitespace in value prefixes' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('a=  a')
      _(tracestate.to_h).must_equal('a' => '  a')
    end
    it 'permits multitenant vendor keys' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('0mg@a-vendor=a')
      _(tracestate.to_h).must_equal('0mg@a-vendor' => 'a')
    end
    it 'supports _-*/ in keys' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string('omg/what_is-this*thing=a')
      _(tracestate.to_h).must_equal('omg/what_is-this*thing' => 'a')
    end
  end

  describe '.from_hash' do
    it 'skips invalid members' do
      h = {
        'commas-,-are-bad' => 'commas-are-bad',
        'commas-are-bad' => 'commas-,-are-bad',
        'no-equality' => 'no=equality',
        'no=equality' => 'no-equality',
        '0xff' => 'key-cant-start-with-a-digit',
        'too-much-value' => '0' * 257,
        'a' * 257 => 'too-much-key',
        'cannot-be-all-space' => '          ',
        'the-good-key' => '  the-good-value',
        '0x_the-vendor/key@my*v3nd0r' => 'another-great-value'
      }
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash(h)
      _(tracestate.to_h).must_equal('the-good-key' => '  the-good-value', '0x_the-vendor/key@my*v3nd0r' => 'another-great-value')
    end
    it 'will not exceed 32 members' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash(Array.new(33) { |n| [n.to_s, n.to_s] }.to_h)
      _(tracestate.to_h.size).must_be :<=, 32
    end
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
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash(Array.new(31) { |n| [n.to_s, n.to_s] }.to_h)
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
      old_tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a')
      new_tracestate = old_tracestate.delete('a')
      _(new_tracestate).wont_equal old_tracestate
    end
    it 'deletes the specified key' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a', 'b' => 'b')
      tracestate = tracestate.delete('a')
      _(tracestate.to_h).must_equal('b' => 'b')
    end
  end

  describe '#to_s' do
    let(:header) { 'i=am_a_member,and= so-am_I.' }
    it 'is the inverse of from_string' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_string(header)
      _(tracestate.to_s).must_equal header
    end
    it 'preserves whitespace prefixes in values' do
      h = { 'i' => 'am_a_member', 'and' => ' so-am_I.' }
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash(h)
      _(tracestate.to_s).must_equal header
    end
    it 'returns an empty string when empty?' do
      tracestate = OpenTelemetry::Trace::Tracestate::DEFAULT
      _(tracestate).must_be :empty?
      _(tracestate.to_s).must_be :empty?
    end
    it 'does not terminate a single member with ,' do
      tracestate = OpenTelemetry::Trace::Tracestate.from_hash('a' => 'a')
      _(tracestate.to_s).must_equal 'a=a'
    end
  end

  describe '#empty?' do
    it 'returns true when empty' do
      _(OpenTelemetry::Trace::Tracestate.from_hash({})).must_be :empty?
    end
    it 'returns false when not empty' do
      _(OpenTelemetry::Trace::Tracestate.from_hash('a' => 'b')).wont_be :empty?
    end
  end

  describe '::DEFAULT' do
    it 'returns empty tracestate' do
      _(OpenTelemetry::Trace::Tracestate::DEFAULT.to_h).must_be :empty?
    end
  end
end
