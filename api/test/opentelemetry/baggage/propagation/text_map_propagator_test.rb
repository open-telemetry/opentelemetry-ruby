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

  describe '#extract' do
    describe 'valid headers' do
      it 'extracts key-value pairs' do
        carrier = { header_key => 'key1=val1,key2=val2' }
        context = propagator.extract(carrier, context: Context.empty)
        assert_value(context, 'key1', 'val1')
        assert_value(context, 'key2', 'val2')
      end

      it 'extracts entries with spaces' do
        carrier = { header_key => ' key1  =  val1,  key2=val2 ' }
        context = propagator.extract(carrier, context: Context.empty)
        assert_value(context, 'key1', 'val1')
        assert_value(context, 'key2', 'val2')
      end

      it 'preserves properties' do
        carrier = { header_key => 'key1=val1,key2=val2;prop1=propval1;prop2=propval2' }
        context = propagator.extract(carrier, context: Context.empty)
        assert_value(context, 'key1', 'val1')
        assert_value(context, 'key2', 'val2', 'prop1=propval1;prop2=propval2')
      end

      it 'extracts urlencoded entries' do
        carrier = { header_key => 'key%3A1=val1%2C1,key%3A2=val2%2C2' }
        context = propagator.extract(carrier, context: Context.empty)
        assert_value(context, 'key:1', 'val1,1')
        assert_value(context, 'key:2', 'val2,2')
      end
    end

    describe 'invalid or no-op headers' do
      it 'returns the same context object when the headers are not present' do
        carrier = {}
        empty_context = Context.empty
        context = propagator.extract(carrier, context: empty_context)
        _(context.object_id).must_equal(empty_context.object_id)
      end

      it 'returns the same context object when the baggage value is a 0-length string' do
        carrier = { header_key => '' }
        empty_context = Context.empty
        context = propagator.extract(carrier, context: empty_context)
        _(context.object_id).must_equal(empty_context.object_id)
      end

      it 'does not test for an "empty" string and still replaces the context' do
        carrier = { header_key => '   ' }
        empty_context = Context.empty
        context = propagator.extract(carrier, context: empty_context)
        _(context.object_id).wont_equal(empty_context.object_id)
      end
    end
  end

  describe '#inject' do
    it 'injects baggage' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_value('key1', 'val1')
        b.set_value('key2', 'val2')
      end

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=val1,key2=val2')
    end

    it 'injects numeric baggage' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_value('key1', 1)
        b.set_value('key2', 3.14)
      end

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=1,key2=3.14')
    end

    it 'injects boolean baggage' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_value('key1', true)
        b.set_value('key2', false)
      end

      carrier = {}
      propagator.inject(carrier, context: context)

      _(carrier[header_key]).must_equal('key1=true,key2=false')
    end

    it 'does not inject baggage key is not present' do
      carrier = {}
      propagator.inject(carrier, context: Context.empty)
      _(carrier).must_be(:empty?)
    end

    it 'injects properties' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_value('key1', 'val1')
        b.set_value('key2', 'val2', metadata: 'prop1=propval1;prop2=propval2')
      end

      carrier = {}
      propagator.inject(carrier, context: context)
      _(carrier[header_key]).must_equal('key1=val1,key2=val2;prop1=propval1;prop2=propval2')
    end

    it 'enforces max of 180 name-value pairs' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        (0..180).each do |i|
          b.set_value("k#{i}", "v#{i}")
        end
      end

      carrier = {}
      propagator.inject(carrier, context: context)
      result = carrier[header_key]

      # expect keys indexed from 0 to 180 to be in baggage, but only 0 to 179 in the result
      _(OpenTelemetry::Baggage.value('k180', context: context)).wont_be_nil
      (0...180).each do |i|
        _(result).must_include("k#{i}")
      end
      _(result).wont_include('k180')
    end

    it 'enforces max entry length of 4096' do
      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        b.set_value('key1', 'x' * 4092)
        b.set_value('key2', 'val2')
      end

      carrier = {}
      propagator.inject(carrier, context: context)
      result = carrier[header_key]

      _(result).wont_include('key1')
      _(result).must_include('key2')
    end

    it 'enforces total length of 8192 chars' do
      # each entry will be 100 chars long including '=' and ','
      # the last entry will be 99 chars long (it doesn't have a trailing ',')
      keys = (0..81).map { |i| "k#{i.to_s.rjust(48, '0')}" }
      values = (0..81).map { |i| "v#{i.to_s.rjust(48, '0')}" }

      context = OpenTelemetry::Baggage.build(context: OpenTelemetry::Context.empty) do |b|
        keys.zip(values).each { |k, v| b.set_value(k, v) }
      end

      carrier = {}
      propagator.inject(carrier, context: context)
      result = carrier[header_key]

      keys.take(81).each { |k| _(result).must_include(k) }
      _(result).wont_include(keys.last)
      _(result.size).must_equal(8099)
    end
  end
end

def assert_value(context, key, value, metadata = nil)
  entry = OpenTelemetry::Baggage.raw_entries(context: context)[key]
  _(entry).wont_be_nil
  _(entry.value).must_equal(value)
  _(entry.metadata).must_equal(metadata)
end
