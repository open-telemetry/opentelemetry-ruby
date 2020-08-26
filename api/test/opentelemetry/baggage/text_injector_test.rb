# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapInjector do
  let(:injector) do
    OpenTelemetry::Baggage::Propagation::TextMapInjector.new
  end
  let(:header_key) do
    'Baggage'
  end
  let(:context_key) do
    OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
  end

  describe '#inject' do
    it 'injects baggage' do
      context = Context.empty.set_value(context_key, 'key1' => 'val1',
                                                     'key2' => 'val2')

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric baggage' do
      context = Context.empty.set_value(context_key, 'key1' => 1,
                                                     'key2' => 3.14)

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean baggage' do
      context = Context.empty.set_value(context_key, 'key1' => true,
                                                     'key2' => false)

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
  end
end
