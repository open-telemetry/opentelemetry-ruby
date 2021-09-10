# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage do
  Context = OpenTelemetry::Context
  let(:manager) { OpenTelemetry::Baggage }

  after do
    Context.clear
  end

  describe '.set_value' do
    describe 'explicit context' do
      it 'sets key/value in context' do
        ctx = Context.empty
        _(manager.value('foo', context: ctx)).must_be_nil

        ctx2 = manager.set_value('foo', 'bar', context: ctx)
        _(manager.value('foo', context: ctx2)).must_equal('bar')

        _(manager.value('foo', context: ctx)).must_be_nil
      end
    end

    describe '.values' do
      describe 'explicit context' do
        it 'returns context with empty baggage' do
          ctx = manager.set_value('foo', 'bar', context: Context.empty)
          values = manager.values(context: ctx)
          _(values.size).must_equal(1)
          _(values['foo']).must_equal('bar')

          ctx2 = manager.clear(context: ctx)
          _(manager.values(context: ctx2)).must_equal({})
        end

        it 'returns all entries' do
          ctx = manager.build do |baggage|
            baggage.set_value('k1', 'v1')
            baggage.set_value('k2', 'v2')
          end
          values = manager.values(context: ctx)
          _(values.size).must_equal(2)
          _(values['k1']).must_equal('v1')
          _(values['k2']).must_equal('v2')
        end
      end

      describe 'implicit context' do
        it 'returns context with empty baggage' do
          Context.with_current(manager.set_value('foo', 'bar')) do
            values = manager.values
            _(values.size).must_equal(1)
            _(values['foo']).must_equal('bar')
          end

          _(manager.values).must_equal({})
        end
      end
    end

    describe 'implicit context' do
      it 'sets key/value in implicit context' do
        _(manager.value('foo')).must_be_nil

        Context.with_current(manager.set_value('foo', 'bar')) do
          _(manager.value('foo')).must_equal('bar')
        end

        _(manager.value('foo')).must_be_nil
      end
    end
  end

  describe '.clear' do
    describe 'explicit context' do
      it 'returns context with empty baggage' do
        ctx = manager.set_value('foo', 'bar', context: Context.empty)
        _(manager.value('foo', context: ctx)).must_equal('bar')

        ctx2 = manager.clear(context: ctx)
        _(manager.value('foo', context: ctx2)).must_be_nil
      end
    end

    describe 'implicit context' do
      it 'returns context with empty baggage' do
        ctx = manager.set_value('foo', 'bar')
        _(manager.value('foo', context: ctx)).must_equal('bar')

        ctx2 = manager.clear
        _(manager.value('foo', context: ctx2)).must_be_nil
      end
    end
  end

  describe '.remove_value' do
    describe 'explicit context' do
      it 'returns context with key removed from baggage' do
        ctx = manager.set_value('foo', 'bar', context: Context.empty)
        _(manager.value('foo', context: ctx)).must_equal('bar')

        ctx2 = manager.remove_value('foo', context: ctx)
        _(manager.value('foo', context: ctx2)).must_be_nil
      end
    end

    describe 'implicit context' do
      it 'returns context with key removed from baggage' do
        Context.with_current(manager.set_value('foo', 'bar')) do
          _(manager.value('foo')).must_equal('bar')

          ctx = manager.remove_value('foo')
          _(manager.value('foo', context: ctx)).must_be_nil
        end
      end
    end
  end

  describe '.build' do
    let(:initial_context) { manager.set_value('k1', 'v1') }

    describe 'explicit context' do
      it 'sets entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.set_value('k2', 'v2')
          baggage.set_value('k3', 'v3')
        end
        _(manager.value('k1', context: ctx)).must_equal('v1')
        _(manager.value('k2', context: ctx)).must_equal('v2')
        _(manager.value('k3', context: ctx)).must_equal('v3')
      end

      it 'removes entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.remove_value('k1')
          baggage.set_value('k2', 'v2')
        end
        _(manager.value('k1', context: ctx)).must_be_nil
        _(manager.value('k2', context: ctx)).must_equal('v2')
      end

      it 'clears entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.clear
          baggage.set_value('k2', 'v2')
        end
        _(manager.value('k1', context: ctx)).must_be_nil
        _(manager.value('k2', context: ctx)).must_equal('v2')
      end
    end

    describe 'implicit context' do
      it 'sets entries' do
        Context.with_current(initial_context) do
          ctx = manager.build do |baggage|
            baggage.set_value('k2', 'v2')
            baggage.set_value('k3', 'v3')
          end
          Context.with_current(ctx) do
            _(manager.value('k1')).must_equal('v1')
            _(manager.value('k2')).must_equal('v2')
            _(manager.value('k3')).must_equal('v3')
          end
        end
      end

      it 'removes entries' do
        Context.with_current(initial_context) do
          _(manager.value('k1')).must_equal('v1')

          ctx = manager.build do |baggage|
            baggage.remove_value('k1')
            baggage.set_value('k2', 'v2')
          end

          Context.with_current(ctx) do
            _(manager.value('k1')).must_be_nil
            _(manager.value('k2')).must_equal('v2')
          end
        end
      end

      it 'clears entries' do
        Context.with_current(initial_context) do
          _(manager.value('k1')).must_equal('v1')

          ctx = manager.build do |baggage|
            baggage.clear
            baggage.set_value('k2', 'v2')
          end

          Context.with_current(ctx) do
            _(manager.value('k1')).must_be_nil
            _(manager.value('k2')).must_equal('v2')
          end
        end
      end
    end
  end
end
