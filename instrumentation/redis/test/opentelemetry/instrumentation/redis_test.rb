# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Redis do
  let(:redis) { OpenTelemetry::Instrumentation::Redis }

  describe '#attributes' do
    let(:attributes) { { 'foo' => 'bar' } }

    it 'returns an empty hash by default' do
      _(redis.attributes).must_equal({})
    end

    it 'returns the current attributes hash' do
      redis.with_attributes(attributes) do
        _(redis.attributes).must_equal(attributes)
      end
    end

    it 'returns the current attributes hash from the provided context' do
      context = redis.context_with_attributes(attributes, parent_context: OpenTelemetry::Context.empty)
      _(redis.attributes).wont_equal(attributes)
      _(redis.attributes(context)).must_equal(attributes)
    end
  end

  describe '#with_attributes' do
    it 'yields the passed in attributes' do
      redis.with_attributes('foo' => 'bar') do |attributes|
        _(attributes).must_equal('foo' => 'bar')
      end
    end

    it 'yields context containing attributes' do
      redis.with_attributes('foo' => 'bar') do |attributes, context|
        _(context).must_equal(OpenTelemetry::Context.current)
        _(redis.attributes).must_equal(attributes)
      end
    end

    it 'should reactivate the attributes after the block' do
      redis.with_attributes('foo' => 'bar') do
        _(redis.attributes).must_equal('foo' => 'bar')

        redis.with_attributes('foo' => 'baz') do
          _(redis.attributes).must_equal('foo' => 'baz')
        end

        _(redis.attributes).must_equal('foo' => 'bar')
      end
    end

    it 'should merge attributes' do
      redis.with_attributes(
        'a' => '1',
        'c' => '2'
      ) do
        _(redis.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )

        redis.with_attributes(
          'a' => '0',
          'b' => '1'
        ) do
          _(redis.attributes).must_equal(
            'a' => '0',
            'b' => '1',
            'c' => '2'
          )
        end

        _(redis.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )
      end
    end
  end

  describe '#context_with_attributes' do
    it 'returns a context containing attributes' do
      attrs = { 'foo' => 'bar' }
      ctx = redis.context_with_attributes(attrs)
      _(redis.attributes(ctx)).must_equal(attrs)
    end

    it 'returns a context containing attributes' do
      parent_ctx = OpenTelemetry::Context.empty.set_value('foo', 'bar')
      ctx = redis.context_with_attributes({ 'bar' => 'baz' }, parent_context: parent_ctx)
      _(redis.attributes(ctx)).must_equal('bar' => 'baz')
      _(ctx.value('foo')).must_equal('bar')
    end
  end
end
