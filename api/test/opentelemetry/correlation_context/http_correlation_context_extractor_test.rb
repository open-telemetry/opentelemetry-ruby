# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextExtractor do
  let(:extractor) do
    OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextExtractor.new
  end
  let(:header_key) do
    'correlationcontext'
  end
  let(:context_key) do
    OpenTelemetry::CorrelationContext::Propagation::ContextKeys.span_context_key
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = extractor.extract(Context.empty, carrier)
        correlations = context[context_key]
        _(correlations['key1']).must_equal('val1')
        _(correlations['key2']).must_equal('val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        context = extractor.extract(Context.empty, carrier)
        correlations = context[context_key]
        _(correlations['key1']).must_equal('val1')
        _(correlations['key2']).must_equal('val2')
      end

      it 'ignores properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        context = extractor.extract(Context.empty, carrier)
        correlations = context[context_key]
        _(correlations['key1']).must_equal('val1')
        _(correlations['key2']).must_equal('val2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        context = extractor.extract(Context.empty, carrier)
        correlations = context[context_key]
        _(correlations['key:1']).must_equal('val1,1')
        _(correlations['key:2']).must_equal('val2,2')
      end
    end
  end
end
