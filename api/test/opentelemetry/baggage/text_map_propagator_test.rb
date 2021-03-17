# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Propagation::TextMapPropagator do
  let(:propagator) do
    OpenTelemetry::Baggage::Propagation::TextMapPropagator.new
  end
  let(:header_key) do
    'baggage'
  end
  let(:context_key) do
    OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
  end

  describe '#inject' do
    it 'injects baggage' do
      context = Context.empty.set_value(context_key, 'key1' => 'val1',
                                                     'key2' => 'val2')

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric baggage' do
      context = Context.empty.set_value(context_key, 'key1' => 1,
                                                     'key2' => 3.14)

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean baggage' do
      context = Context.empty.set_value(context_key, 'key1' => true,
                                                     'key2' => false)

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=true,key2=false')
    end

    it 'does not inject baggage key is not present' do
      carrier = {}
      propagator.inject(carrier, context: Context.empty)
      _(carrier).must_be(:empty?)
    end

    it 'injects boolean baggage' do
      context = Context.empty.set_value(context_key, {})

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier).must_be(:empty?)
    end
  end

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = propagator.extract(carrier, context: Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        context = propagator.extract(carrier, context: Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'ignores properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        context = propagator.extract(carrier, context: Context.empty)
        baggage = context[context_key]
        _(baggage['key1']).must_equal('val1')
        _(baggage['key2']).must_equal('val2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        context = propagator.extract(carrier, context: Context.empty)
        baggage = context[context_key]
        _(baggage['key:1']).must_equal('val1,1')
        _(baggage['key:2']).must_equal('val2,2')
      end

      it 'returns original context on failure' do
        orig_context = Context.empty.set_value('k1', 'v1')
        carrier = { header_key => 'key1=val1,key2=val2' }
        getter = Class.new do
          def get(*)
            raise 'mwahaha'
          end
        end.new
        context = propagator.extract(carrier, context: orig_context, getter: getter)
        _(context).must_equal(orig_context)
      end
    end
  end
end
