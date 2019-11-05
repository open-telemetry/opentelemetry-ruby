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
end
