# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapInjector do
  let(:injector) do
    OpenTelemetry::Baggage::Propagation::TextMapInjector.new
  end
  let(:header_key) do
    'baggage'
  end
  let(:context_key) do
    OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
  end

  describe '#inject' do
    it 'injects baggage' do
      context = set_baggage('key1', 'val1')
      context = set_baggage('key2', 'val2', context: context)

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric baggage' do
      context = set_baggage('key1', 1)
      context = set_baggage('key2', 3.14, context: context)

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean baggage' do
      context = set_baggage('key1', true)
      context = set_baggage('key2', false, context: context)

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=true,key2=false')
    end

    it 'does not inject baggage key is not present' do
      carrier = injector.inject({}, Context.empty)
      _(carrier).must_be(:empty?)
    end

    it 'injects boolean baggage' do
      context = Context.empty.set_value(context_key, {})

      carrier = injector.inject({}, context)

      _(carrier).must_be(:empty?)
    end

    it 'injects properties' do
      context = set_baggage('key1', 'val1')
      context = set_baggage('key2', 'val2', metadata: 'prop1=propval1;prop2=propval2', context: context)
      carrier = injector.inject({}, context)
      _(carrier[header_key]).must_equal('key1=val1,key2=val2;prop1=propval1;prop2=propval2')
    end
  end
end

def set_baggage(key, value, metadata: nil, context: Context.empty)
  baggage = context[context_key] || {}
  context.set_value(context_key, baggage.merge(key => OpenTelemetry::Baggage::Entry.new(value, metadata)))
end
