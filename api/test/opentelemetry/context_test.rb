# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'logger'
require 'stringio'

describe OpenTelemetry::Context do
  Context = OpenTelemetry::Context

  after do
    Context.clear
  end

  let(:foo_key) { Context.create_key('foo') }
  let(:bar_key) { Context.create_key('bar') }
  let(:baz_key) { Context.create_key('baz') }
  let(:new_context) { Context.empty.set_value(foo_key, 'bar') }

  describe '.current' do
    it 'defaults to the root context' do
      _(Context.current).must_equal(Context::ROOT)
    end
  end

  describe '.with_current' do
    it 'handles nested contexts' do
      c1 = new_context
      Context.with_current(c1) do
        _(Context.current).must_equal(c1)
        c2 = Context.current.set_value(bar_key, 'baz')
        Context.with_current(c2) do
          _(Context.current).must_equal(c2)
        end
        _(Context.current).must_equal(c1)
      end
    end

    it 'resets context when an exception is raised' do
      c1 = new_context
      Context.current = c1

      _(proc do
        c2 = Context.current.set_value(bar_key, 'baz')
        Context.with_current(c2) do
          raise 'oops'
        end
      end).must_raise(StandardError)

      _(Context.current).must_equal(c1)
    end
  end

  describe '.with_value' do
    it 'executes block within new context' do
      orig_ctx = Context.current

      block_called = false

      Context.with_value(foo_key, 'bar') do |value|
        _(Context.current.value(foo_key)).must_equal('bar')
        _(value).must_equal('bar')
        block_called = true
      end

      _(Context.current).must_equal(orig_ctx)
      _(block_called).must_equal(true)
    end
  end

  describe '#value' do
    it 'returns corresponding value for key' do
      ctx = new_context
      _(ctx.value(foo_key)).must_equal('bar')
    end
  end

  describe '.with_values' do
    it 'executes block within new context' do
      orig_ctx = Context.current

      block_called = false

      Context.with_values(foo_key => 'bar', bar_key => 'baz') do |values|
        _(Context.current.value(foo_key)).must_equal('bar')
        _(Context.current.value(bar_key)).must_equal('baz')
        _(values).must_equal(foo_key => 'bar', bar_key => 'baz')
        block_called = true
      end

      _(Context.current).must_equal(orig_ctx)
      _(block_called).must_equal(true)
    end
  end

  describe '#set_values' do
    it 'assigns multiple values' do
      ctx = new_context
      ctx2 = ctx.set_values(bar_key => 'baz', baz_key => 'quux')
      _(ctx2.value(foo_key)).must_equal('bar')
      _(ctx2.value(bar_key)).must_equal('baz')
      _(ctx2.value(baz_key)).must_equal('quux')
    end

    it 'merges new values' do
      ctx = new_context
      ctx2 = ctx.set_values(foo_key => 'foobar', bar_key => 'baz')
      _(ctx2.value(foo_key)).must_equal('foobar')
      _(ctx2.value(bar_key)).must_equal('baz')
    end
  end

  describe '#update' do
    it 'returns new context with entry' do
      c1 = Context.current
      c2 = c1.set_value(foo_key, 'bar')
      _(c1.value(foo_key)).must_be_nil
      _(c2.value(foo_key)).must_equal('bar')
    end
  end

  describe 'threading' do
    it 'unwinds the stack on each thread' do
      ctx = new_context
      t1_ctx_before = Context.current
      Context.with_current(ctx) do
        Thread.new do
          t2_ctx_before = Context.current
          Context.with_current(ctx) do
            Context.with_value(bar_key, 'foobar') do
              _(Context.current).wont_equal(t2_ctx_before)
            end
          end
          _(Context.current).must_equal(t2_ctx_before)
        end.join
        Context.with_value(bar_key, 'baz') do
          _(Context.current).wont_equal(t1_ctx_before)
        end
      end
      _(Context.current).must_equal(t1_ctx_before)
    end

    it 'scopes changes to the current thread' do
      ctx = new_context
      Context.with_current(ctx) do
        Thread.new do
          Context.with_current(ctx) do
            Context.with_value(bar_key, 'foobar') do
              Thread.pass
              _(Context.current[foo_key]).must_equal('bar')
              _(Context.current[bar_key]).must_equal('foobar')
            end
            _(Context.current[bar_key]).must_be_nil
          end
        end.join
        Context.with_value(bar_key, 'baz') do
          Thread.pass
          _(Context.current[foo_key]).must_equal('bar')
          _(Context.current[bar_key]).must_equal('baz')
        end
        _(Context.current[bar_key]).must_be_nil
      end
    end
  end
end
