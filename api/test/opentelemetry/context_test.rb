# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context do
  Context = OpenTelemetry::Context

  before do
    Context.current = nil
  end

  describe '.current' do
    it 'defaults to the root context' do
      _(Context.current).must_equal(Context::ROOT)
    end
  end

  describe '#get' do
    it 'returns corresponding value for key' do
      ctx = Context.new(nil, 'foo' => 'bar')
      _(ctx.get('foo')).must_equal('bar')
    end
  end

  describe '#set' do
    it 'returns new context with entry' do
      c1 = Context.current
      c2 = c1.set('foo', 'bar')
      _(c1.get('foo')).must_be_nil
      _(c2.get('foo')).must_equal('bar')
    end
  end

  describe '#attach' do
    it 'sets context to current' do
      orig_ctx = Context.current
      new_ctx = Context.current.set('foo', 'bar')
      prev_ctx = new_ctx.attach
      _(Context.current).must_equal(new_ctx)
      _(prev_ctx).must_equal(orig_ctx)
    end
  end

  describe '#detach' do
    it 'restores parent context by default' do
      new_ctx = Context.current.set('foo', 'bar')
      prev_ctx = new_ctx.attach
      _(Context.current).must_equal(new_ctx)

      new_ctx.detach
      _(Context.current).must_equal(prev_ctx)
    end

    it 'restores ctx passed in' do
      orig_ctx = Context.current
      ctx1 = orig_ctx.set('foo', 'bar')
      ctx2 = ctx1.set('bar', 'baz')

      ctx1.attach
      prev_ctx = ctx2.attach
      _(Context.current).must_equal(ctx2)

      ctx2.detach(orig_ctx)
      _(Context.current).must_equal(orig_ctx)
      _(Context.current).wont_equal(prev_ctx)
    end
  end
end
