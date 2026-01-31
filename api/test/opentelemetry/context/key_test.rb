# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Context::Key do
  after do
    Context.clear
  end

  it 'can be used for indexing' do
    key = Context::Key.new('k')
    ctx = Context.empty.set_value(key, 'v')
    _(ctx.value(key)).must_equal('v')
  end

  it 'indexes properly with duplicate name' do
    k1 = Context::Key.new('k')
    k2 = Context::Key.new('k')
    ctx = Context.empty.set_value(k1, 'v1')
    ctx = ctx.set_value(k2, 'v2')
    _(ctx.value(k1)).must_equal('v1')
    _(ctx.value(k2)).must_equal('v2')
  end

  describe '.get' do
    it 'retrieves associated entry from Context' do
      key = Context::Key.new('k')
      ctx = Context.empty.set_value(key, 'v')
      _(key.get(ctx)).must_equal('v')
    end
  end
end
