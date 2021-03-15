# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapExtractor do
  class MockBaggage
    class MockBuilder
      attr_reader :entries

      def initialize
        @entries = {}
      end

      def set_value(key, value, metadata: nil)
        @entries[key] = { value: value, metadata: metadata }
      end
    end

    def builder
      @builder ||= MockBuilder.new
    end

    def build(context: _)
      yield builder
      OpenTelemetry::Context.empty
    end

    def entries
      builder.entries
    end
  end

  let(:extractor) do
    OpenTelemetry::Baggage::Propagation::TextMapExtractor.new
  end
  let(:header_key) { 'baggage' }
  let(:mock_baggage) { MockBaggage.new }

  before do
    @original_baggage_mgr = OpenTelemetry.baggage
    OpenTelemetry.baggage = mock_baggage
  end

  after do
    OpenTelemetry.baggage = @original_baggage_mgr
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        extractor.extract(carrier, Context.empty)
        assert_entry('key1', 'val1')
        assert_entry('key2', 'val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        extractor.extract(carrier, Context.empty)
        assert_entry('key1', 'val1')
        assert_entry('key2', 'val2')
      end

      it 'preserves properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        extractor.extract(carrier, Context.empty)
        assert_entry('key1', 'val1')
        assert_entry('key2', 'val2', 'prop1=propval1;prop2=propval2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        extractor.extract(carrier, Context.empty)
        assert_entry('key:1', 'val1,1')
        assert_entry('key:2', 'val2,2')
      end
    end
  end
end

def assert_entry(key, value, metadata = nil)
  entry = mock_baggage.entries.fetch(key, {})
  _(entry[:value]).must_equal(value)
  _(entry[:metadata]).must_equal(metadata)
end
