# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextInjector do
  let(:injector) do
    OpenTelemetry::CorrelationContext::Propagation::HttpCorrelationContextInjector.new
  end
  let(:header_key) do
    'correlationcontext'
  end
  let(:context_key) do
    OpenTelemetry::CorrelationContext::Propagation::ContextKeys.span_context_key
  end

  describe '#inject' do
    it 'injects correlations' do
      context = Context.empty.set_value(context_key, 'key1' => 'val1',
                                                     'key2' => 'val2')

      carrier = injector.inject(context, {})

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric correlations' do
      context = Context.empty.set_value(context_key, 'key1' => 1,
                                                     'key2' => 3.14)

      carrier = injector.inject(context, {})

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean correlations' do
      context = Context.empty.set_value(context_key, 'key1' => true,
                                                     'key2' => false)

      carrier = injector.inject(context, {})

      _(carrier[header_key]).must_equal('key1=true,key2=false')
    end

    it 'does not inject correlation key is not present' do
      carrier = injector.inject(Context.empty, {})
      _(carrier).must_be(:empty?)
    end

    it 'injects boolean correlations' do
      context = Context.empty.set_value(context_key, {})

      carrier = injector.inject(context, {})

      _(carrier).must_be(:empty?)
    end
    # describe 'valid headers' do
    #   it 'extracts key-value pairs' do
    #     carrier = { header_key => 'key1=val1,key2=val2' }
    #     context = extractor.extract(Context.empty, carrier)
    #     correlations = context[context_key]
    #     _(correlations['key1']).must_equal('val1')
    #     _(correlations['key2']).must_equal('val2')
    #   end

    #   it 'extracts entries with spaces' do
    #     carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
    #     context = extractor.extract(Context.empty, carrier)
    #     correlations = context[context_key]
    #     _(correlations['key1']).must_equal('val1')
    #     _(correlations['key2']).must_equal('val2')
    #   end

    #   it 'extracts ignores properties' do
    #     carrier = { header_key => 'key1=val1,key2=val2' }
    #     context = extractor.extract(Context.empty, carrier)
    #     correlations = context[context_key]
    #     _(correlations['key1']).must_equal('val1')
    #     _(correlations['key2']).must_equal('val2')
    #   end

    #   it 'extracts urlencoded entries' do
    #     carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
    #     context = extractor.extract(Context.empty, carrier)
    #     correlations = context[context_key]
    #     _(correlations['key:1']).must_equal('val1,1')
    #     _(correlations['key:2']).must_equal('val2,2')
    #   end
    # end
  end
end
