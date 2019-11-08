# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Baggage::Manager do
  Manager = OpenTelemetry::SDK::Baggage::Manager

  describe '.set_value' do
    it 'sets key/value in baggage' do
      ctx = OpenTelemetry::Context.empty
      _(Manager.value(ctx, 'foo')).must_be_nil

      ctx2 = Manager.set_value(ctx, 'foo', 'bar')
      _(Manager.value(ctx2, 'foo')).must_equal('bar')

      _(Manager.value(ctx, 'foo')).must_be_nil
    end
  end

  describe '.clear' do
    it 'returns context with empty baggage' do
      ctx = Manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(Manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = Manager.clear(ctx)
      _(Manager.value(ctx2, 'foo')).must_be_nil
    end
  end

  describe '.remove_value' do
    it 'returns context with key removed from baggage' do
      ctx = Manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(Manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = Manager.remove_value(ctx, 'foo')
      _(Manager.value(ctx2, 'foo')).must_be_nil
    end

    it 'returns same context if key does not exist' do
      ctx = Manager.set_value(OpenTelemetry::Context.empty, 'foo', 'bar')
      _(Manager.value(ctx, 'foo')).must_equal('bar')

      ctx2 = Manager.remove_value(ctx, 'nonexistant-key')
      _(ctx2).must_equal(ctx)
    end
  end
end
