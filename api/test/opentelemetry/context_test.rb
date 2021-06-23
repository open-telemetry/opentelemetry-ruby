# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'logger'
require 'stringio'

describe OpenTelemetry::Context do
  Context = OpenTelemetry::Context

  after { Context.clear }

  let(:foo_key) { Context.create_key('foo') }
  let(:bar_key) { Context.create_key('bar') }
  let(:baz_key) { Context.create_key('baz') }
  let(:new_context) { Context.empty.set_value(foo_key, 'bar') }

  describe '.create_key' do
    it 'returns a Context::Key' do
      key = Context.create_key('testing')
      _(key).must_be_instance_of(Context::Key)
      _(key.name).must_equal('testing')
    end
  end

  describe '.current' do
    it 'defaults to the root context' do
      _(Context.current).must_equal(Context::ROOT)
    end
  end

  describe '.attach' do
    it 'returns a token to be used when detaching' do
      c1_token = Context.attach(new_context)
      _(c1_token).wont_be_nil
    end

    it 'sets the current context' do
      c1 = new_context
      Context.attach(c1)
      _(Context.current).must_equal(c1)
      _(Context.current[foo_key]).must_equal('bar')

      c2 = Context.current.set_value(foo_key, 'c2')
      Context.attach(c2)
      _(Context.current).must_equal(c2)
      _(Context.current[foo_key]).must_equal('c2')

      c3 = Context.current.set_value(foo_key, 'c3')
      Context.attach(c3)
      _(Context.current).must_equal(c3)
      _(Context.current[foo_key]).must_equal('c3')
    end

    it 'allows for attaching the same context multiple times' do
      c1 = new_context
      Context.attach(c1)
      Context.attach(Context.current)
      Context.attach(Context.current)
      Context.attach(Context.current)

      Context.detach
      _(Context.current).must_equal(c1)
      Context.detach
      _(Context.current).must_equal(c1)
      Context.detach
      _(Context.current).must_equal(c1)
      Context.detach
      _(Context.current).must_equal(Context::ROOT)
    end
  end

  describe '.detach' do
    before do
      @log_stream = StringIO.new
      @_logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(@log_stream)
    end

    after do
      OpenTelemetry.logger = @_logger
    end

    it 'restores the context' do
      c1_token = Context.attach(new_context)
      _(Context.current).must_equal(new_context)

      Context.detach(c1_token)
      _(Context.current).must_equal(Context::ROOT)

      _(@log_stream.string).must_be_empty
    end

    it 'warns mismatched detach calls' do
      c1 = new_context
      c1_token = Context.attach(c1)

      c2 = Context.current.set_value(foo_key, 'c2')
      Context.attach(c2)

      c3 = Context.current.set_value(foo_key, 'c3')
      Context.attach(c3)

      Context.detach(c1_token)

      _(@log_stream.string).must_match(/Calls to detach should match corresponding calls to attach/)
    end

    it 'detaches to the previous context' do
      c1 = new_context
      Context.attach(c1)

      c2 = Context.current.set_value(foo_key, 'c2')
      Context.attach(c2)

      c3 = Context.current.set_value(foo_key, 'c3')
      Context.attach(c3)

      _(Context.current).must_equal(c3)

      Context.detach
      _(Context.current).must_equal(c2)

      Context.detach
      _(Context.current).must_equal(c1)

      Context.detach
      _(Context.current).must_equal(Context::ROOT)
      _(@log_stream.string).must_be_empty
    end

    it 'detaching at the root leaves the root as the current context' do
      Context.detach
      _(Context.current).must_equal(Context::ROOT)
      _(@log_stream.string).must_be_empty
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

    it 'yields the current context to the block' do
      ctx = new_context
      Context.with_current(ctx) do |c|
        _(c).must_equal(ctx)
      end
    end
  end

  describe '.with_value' do
    it 'executes block within new context' do
      orig_ctx = Context.current

      block_called = false

      Context.with_value(foo_key, 'bar') do |_, value|
        _(Context.current.value(foo_key)).must_equal('bar')
        _(value).must_equal('bar')
        block_called = true
      end

      _(Context.current).must_equal(orig_ctx)
      _(block_called).must_equal(true)
    end

    it 'yields the current context and value to the block' do
      Context.with_value(foo_key, 'bar') do |c, v|
        _(v).must_equal('bar')
        _(c.value(foo_key)).must_equal('bar')
      end
    end
  end

  describe '.with_values' do
    it 'executes block within new context' do
      orig_ctx = Context.current

      block_called = false

      Context.with_values(foo_key => 'bar', bar_key => 'baz') do |_, values|
        _(Context.current.value(foo_key)).must_equal('bar')
        _(Context.current.value(bar_key)).must_equal('baz')
        _(values).must_equal(foo_key => 'bar', bar_key => 'baz')
        block_called = true
      end

      _(Context.current).must_equal(orig_ctx)
      _(block_called).must_equal(true)
    end

    it 'yields the current context and values to the block' do
      values = { foo_key => 'bar', bar_key => 'baz' }
      Context.with_values(values) do |c, v|
        _(v).must_equal(values)
        _(c.value(foo_key)).must_equal('bar')
        _(c.value(bar_key)).must_equal('baz')
      end
    end
  end

  describe '.value' do
    it 'returns the value from the current context' do
      Context.attach(new_context)
      _(Context.value(foo_key)).must_equal('bar')

      c2 = Context.current.set_value(bar_key, 'baz')
      Context.attach(c2)
      _(Context.value(bar_key)).must_equal('baz')
    end
  end

  describe '.clear' do
    it 'clears the context' do
      Context.attach(new_context)
      _(Context.current).must_equal(new_context)

      Context.clear

      _(Context.current).must_equal(Context::ROOT)
    end
  end

  describe '#value' do
    it 'returns corresponding value for key' do
      ctx = new_context
      _(ctx.value(foo_key)).must_equal('bar')
    end
  end

  describe '#set_value' do
    it 'returns new context with entry' do
      c1 = Context.current
      c2 = c1.set_value(foo_key, 'bar')
      _(c1.value(foo_key)).must_be_nil
      _(c2.value(foo_key)).must_equal('bar')
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
