# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Baggage::Manager do
  let(:manager) { OpenTelemetry::SDK::Baggage::Manager.new }

  describe '.set_value' do
    it 'sets key/value in baggage' do
      ctx = OpenTelemetry::Context.empty
      _(manager.value(ctx, 'foo')).must_be_nil

      ctx2 = manager.set_value(ctx, 'foo', 'bar')
      _(manager.value(ctx2, 'foo')).must_equal('bar')

      _(manager.value(ctx, 'foo')).must_be_nil
    end
  end

  describe '.clear' do
    it 'returns context with empty baggage' do
      ctx = manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = manager.clear(ctx)
      _(manager.value(ctx2, 'foo')).must_be_nil
    end
  end

  describe '.remove_value' do
    it 'returns context with key removed from baggage' do
      ctx = manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = manager.remove_value(ctx, 'foo')
      _(manager.value(ctx2, 'foo')).must_be_nil
    end

    it 'returns same context if key does not exist' do
      ctx = manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = manager.remove_value(ctx, 'nonexistant-key')
      _(ctx2).must_equal(ctx)
    end
  end
end
