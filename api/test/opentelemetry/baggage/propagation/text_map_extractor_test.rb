# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapExtractor do
  let(:extractor) do
    OpenTelemetry::Baggage::Propagation::TextMapExtractor.new
  end
  let(:header_key) { 'baggage' }

  before do
    @original_baggage_mgr = OpenTelemetry.baggage
    OpenTelemetry.baggage = OpenTelemetry::Baggage::Manager.new
  end

  after do
    OpenTelemetry.baggage = @original_baggage_mgr
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = extractor.extract(carrier, Context.empty)
        assert_entry(context, 'key1', 'val1')
        assert_entry(context, 'key2', 'val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        context = extractor.extract(carrier, Context.empty)
        assert_entry(context, 'key1', 'val1')
        assert_entry(context, 'key2', 'val2')
      end

      it 'preserves properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        context = extractor.extract(carrier, Context.empty)
        assert_entry(context, 'key1', 'val1')
        assert_entry(context, 'key2', 'val2', 'prop1=propval1;prop2=propval2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        context = extractor.extract(carrier, Context.empty)
        assert_entry(context, 'key:1', 'val1,1')
        assert_entry(context, 'key:2', 'val2,2')
      end
    end
  end
end

def assert_entry(context, key, value, metadata = nil)
  entry = OpenTelemetry.baggage.entry(key, context: context)
  _(entry).wont_be_nil
  _(entry.value).must_equal(value)
  _(entry.metadata).must_equal(metadata)
end
