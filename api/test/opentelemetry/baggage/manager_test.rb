# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Baggage::Manager do
  Context = OpenTelemetry::Context
  let(:manager) { OpenTelemetry::Baggage::Manager.new }

  after do
    Context.clear
  end

  describe '.set_value' do
    describe 'explicit context' do
      it 'sets key/value in context' do
        ctx = Context.empty
        _(manager.entry('foo', context: ctx)).must_be_nil

        ctx2 = manager.set_entry('foo', 'bar', context: ctx)
        _(manager.entry('foo', context: ctx2).value).must_equal('bar')

        _(manager.entry('foo', context: ctx)).must_be_nil
      end
    end

    describe '.values' do
      describe 'explicit context' do
        it 'returns context with empty baggage' do
          ctx = manager.set_entry('foo', 'bar', context: Context.empty)
          values = manager.entries(context: ctx)
          _(values.size).must_equal(1)
          _(values['foo'].value).must_equal('bar')

          ctx2 = manager.clear(context: ctx)
          _(manager.entries(context: ctx2)).must_equal({})
        end

        it 'returns all entries' do
          ctx = manager.build do |baggage|
            baggage.set_entry('k1', 'v1')
            baggage.set_entry('k2', 'v2')
          end
          values = manager.entries(context: ctx)
          _(values.size).must_equal(2)
          _(values['k1'].value).must_equal('v1')
          _(values['k2'].value).must_equal('v2')
        end
      end

      describe 'implicit context' do
        it 'returns context with empty baggage' do
          Context.with_current(manager.set_entry('foo', 'bar')) do
            values = manager.entries
            _(values.size).must_equal(1)
            _(values['foo'].value).must_equal('bar')
          end

          _(manager.entries).must_equal({})
        end
      end
    end

    describe 'implicit context' do
      it 'sets key/value in implicit context' do
        _(manager.entry('foo')).must_be_nil

        Context.with_current(manager.set_entry('foo', 'bar')) do
          _(manager.entry('foo').value).must_equal('bar')
        end

        _(manager.entry('foo')).must_be_nil
      end
    end
  end

  describe '.clear' do
    describe 'explicit context' do
      it 'returns context with empty baggage' do
        ctx = manager.set_entry('foo', 'bar', context: Context.empty)
        _(manager.entry('foo', context: ctx).value).must_equal('bar')

        ctx2 = manager.clear(context: ctx)
        _(manager.entry('foo', context: ctx2)).must_be_nil
      end
    end

    describe 'implicit context' do
      it 'returns context with empty baggage' do
        ctx = manager.set_entry('foo', 'bar')
        _(manager.entry('foo', context: ctx).value).must_equal('bar')

        ctx2 = manager.clear
        _(manager.entry('foo', context: ctx2)).must_be_nil
      end
    end
  end

  describe '.remove_value' do
    describe 'explicit context' do
      it 'returns context with key removed from baggage' do
        ctx = manager.set_entry('foo', 'bar', context: Context.empty)
        _(manager.entry('foo', context: ctx).value).must_equal('bar')

        ctx2 = manager.remove_entry('foo', context: ctx)
        _(manager.entry('foo', context: ctx2)).must_be_nil
      end
    end

    describe 'implicit context' do
      it 'returns context with key removed from baggage' do
        Context.with_current(manager.set_entry('foo', 'bar')) do
          _(manager.entry('foo').value).must_equal('bar')

          ctx = manager.remove_entry('foo')
          _(manager.entry('foo', context: ctx)).must_be_nil
        end
      end
    end
  end

  describe '.build' do
    let(:initial_context) { manager.set_entry('k1', 'v1') }

    describe 'explicit context' do
      it 'sets entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.set_entry('k2', 'v2')
          baggage.set_entry('k3', 'v3')
        end
        _(manager.entry('k1', context: ctx).value).must_equal('v1')
        _(manager.entry('k2', context: ctx).value).must_equal('v2')
        _(manager.entry('k3', context: ctx).value).must_equal('v3')
      end

      it 'removes entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.remove_entry('k1')
          baggage.set_entry('k2', 'v2')
        end
        _(manager.entry('k1', context: ctx)).must_be_nil
        _(manager.entry('k2', context: ctx).value).must_equal('v2')
      end

      it 'clears entries' do
        ctx = initial_context
        ctx = manager.build(context: ctx) do |baggage|
          baggage.clear
          baggage.set_entry('k2', 'v2')
        end
        _(manager.entry('k1', context: ctx)).must_be_nil
        _(manager.entry('k2', context: ctx).value).must_equal('v2')
      end
    end

    describe 'implicit context' do
      it 'sets entries' do
        Context.with_current(initial_context) do
          ctx = manager.build do |baggage|
            baggage.set_entry('k2', 'v2')
            baggage.set_entry('k3', 'v3')
          end
          Context.with_current(ctx) do
            _(manager.entry('k1').value).must_equal('v1')
            _(manager.entry('k2').value).must_equal('v2')
            _(manager.entry('k3').value).must_equal('v3')
          end
        end
      end

      it 'removes entries' do
        Context.with_current(initial_context) do
          _(manager.entry('k1').value).must_equal('v1')

          ctx = manager.build do |baggage|
            baggage.remove_entry('k1')
            baggage.set_entry('k2', 'v2')
          end

          Context.with_current(ctx) do
            _(manager.entry('k1')).must_be_nil
            _(manager.entry('k2').value).must_equal('v2')
          end
        end
      end

      it 'clears entries' do
        Context.with_current(initial_context) do
          _(manager.entry('k1').value).must_equal('v1')

          ctx = manager.build do |baggage|
            baggage.clear
            baggage.set_entry('k2', 'v2')
          end

          Context.with_current(ctx) do
            _(manager.entry('k1')).must_be_nil
            _(manager.entry('k2').value).must_equal('v2')
          end
        end
      end
    end
  end
end
