# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapExtractor do
  let(:extractor) do
    OpenTelemetry::Baggage::Propagation::TextMapExtractor.new
  end
  let(:header_key) do
    'baggage'
  end
  let(:context_key) do
    OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = extractor.extract(carrier, Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        context = extractor.extract(carrier, Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'ignores properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        context = extractor.extract(carrier, Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        context = extractor.extract(carrier, Context.empty)
        baggage = context[context_key]
        _(baggage['key:1']).must_equal('val1,1')
        _(baggage['key:2']).must_equal('val2,2')
      end

      it 'returns original context on failure' do
        orig_context = Context.empty.set_value('k1', 'v1')
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = extractor.extract(carrier, orig_context) { raise 'mwahaha' }
        _(context).must_equal(orig_context)
      end
    end
  end
end
