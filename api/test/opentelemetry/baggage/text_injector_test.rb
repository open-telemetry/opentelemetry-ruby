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

  before do
    @original_baggage_mgr = OpenTelemetry.baggage
    OpenTelemetry.baggage = OpenTelemetry::Baggage::Manager.new
  end

  after do
    OpenTelemetry.baggage = @original_baggage_mgr
  end

  describe '#inject' do
    it 'injects baggage' do
      context = OpenTelemetry.baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_entry('key1', 'val1')
        b.set_entry('key2', 'val2')
      end

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric baggage' do
      context = OpenTelemetry.baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_entry('key1', 1)
        b.set_entry('key2', 3.14)
      end

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean baggage' do
      context = OpenTelemetry.baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_entry('key1', true)
        b.set_entry('key2', false)
      end

      carrier = injector.inject({}, context)

      _(carrier[header_key]).must_equal('key1=true,key2=false')
    end

    it 'does not inject baggage key is not present' do
      carrier = injector.inject({}, Context.empty)
      _(carrier).must_be(:empty?)
    end

    it 'injects properties' do
      context = OpenTelemetry.baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_entry('key1', 'val1')
        b.set_entry('key2', 'val2', metadata: 'prop1=propval1;prop2=propval2')
      end

      carrier = injector.inject({}, context)
      _(carrier[header_key]).must_equal('key1=val1,key2=val2;prop1=propval1;prop2=propval2')
    end
  end
end
