# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Common::HTTP::ClientContext do
  let(:client_context) { OpenTelemetry::Common::HTTP::ClientContext }

  describe '#attributes' do
    let(:attributes) { { 'foo' => 'bar' } }

    it 'returns an empty hash by default' do
      _(client_context.attributes).must_equal({})
    end

    it 'returns the current attributes hash' do
      client_context.with_attributes(attributes) do
        _(client_context.attributes).must_equal(attributes)
      end
    end

    it 'returns the current attributes hash from the provided context' do
      context = client_context.context_with_attributes(attributes, parent_context: OpenTelemetry::Context.empty)
      _(client_context.attributes).wont_equal(attributes)
      _(client_context.attributes(context)).must_equal(attributes)
    end
  end

  describe '#with_attributes' do
    it 'yields the passed in attributes' do
      client_context.with_attributes('foo' => 'bar') do |attributes|
        _(attributes).must_equal('foo' => 'bar')
      end
    end

    it 'yields context containing attributes' do
      client_context.with_attributes('foo' => 'bar') do |attributes, context|
        _(context).must_equal(OpenTelemetry::Context.current)
        _(client_context.attributes).must_equal(attributes)
      end
    end

    it 'should reactivate the attributes after the block' do
      client_context.with_attributes('foo' => 'bar') do
        _(client_context.attributes).must_equal('foo' => 'bar')

        client_context.with_attributes('foo' => 'baz') do
          _(client_context.attributes).must_equal('foo' => 'baz')
        end

        _(client_context.attributes).must_equal('foo' => 'bar')
      end
    end

    it 'should merge attributes' do
      client_context.with_attributes(
        'a' => '1',
        'c' => '2'
      ) do
        _(client_context.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )

        client_context.with_attributes(
          'a' => '0',
          'b' => '1'
        ) do
          _(client_context.attributes).must_equal(
            'a' => '0',
            'b' => '1',
            'c' => '2'
          )
        end

        _(client_context.attributes).must_equal(
          'a' => '1',
          'c' => '2'
        )
      end
    end
  end

  describe '#context_with_attributes' do
    it 'returns a context containing attributes' do
      attrs = { 'foo' => 'bar' }
      ctx = client_context.context_with_attributes(attrs)
      _(client_context.attributes(ctx)).must_equal(attrs)
    end

    it 'returns a context containing attributes' do
      parent_ctx = OpenTelemetry::Context.empty.set_value('foo', 'bar')
      ctx = client_context.context_with_attributes({ 'bar' => 'baz' }, parent_context: parent_ctx)
      _(client_context.attributes(ctx)).must_equal('bar' => 'baz')
      _(ctx.value('foo')).must_equal('bar')
    end
  end
end
