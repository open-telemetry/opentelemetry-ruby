# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/distributed_context'
require 'opentelemetry/sdk/distributed_context'

describe OpenTelemetry::SDK::DistributedContext::CorrelationContext do
  CorrelationContext = OpenTelemetry::SDK::DistributedContext::CorrelationContext
  Label = OpenTelemetry::DistributedContext::Label
  Metadata = OpenTelemetry::DistributedContext::Label::Metadata

  let(:foo_label) do
    Label.new(
      key: 'foo',
      value: 'bar'
    )
  end
  let(:bar_label) do
    Label.new(
      key: 'bar',
      value: 'baz'
    )
  end
  let(:baz_label) do
    Label.new(
      key: 'baz',
      value: 'quux'
    )
  end

  describe '.new' do
    it 'does not require any defaults' do
      ctx = CorrelationContext.new
      _(ctx.entries).must_be(:empty?)
    end

    it 'reflects entries passed in' do
      entries = {
        'foo' => foo_label,
        'bar' => bar_label
      }

      ctx = CorrelationContext.new(entries: entries)

      _(ctx.entries).must_equal(entries)
    end

    it 'removes keys specified' do
      entries = {
        'foo' => foo_label,
        'bar' => bar_label
      }

      ctx = CorrelationContext.new(entries: entries, remove_keys: ['bar'])

      _(ctx.entries).must_equal('foo' => foo_label)
    end

    describe 'with parent' do
      let(:parent_ctx) do
        CorrelationContext.new(entries: { 'baz' => baz_label })
      end

      it 'inherits entries' do
        ctx = CorrelationContext.new(parent: parent_ctx)
        _(ctx.entries).must_equal(parent_ctx.entries)
      end

      it 'merges entries' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            'foo' => foo_label,
            'bar' => bar_label
          }
        )
        _(ctx.entries).must_equal(
          'foo' => foo_label,
          'bar' => bar_label,
          'baz' => baz_label
        )
      end

      it 'replaces entries on merge' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            'foo' => foo_label,
            'baz' => bar_label
          }
        )
        _(ctx.entries).must_equal(
          'foo' => foo_label,
          'baz' => bar_label
        )
      end

      it 'removes keys specified' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            'foo' => foo_label,
            'bar' => bar_label
          },
          remove_keys: ['baz']
        )
        _(ctx.entries).must_equal(
          'foo' => foo_label,
          'bar' => bar_label
        )
      end
    end
  end
end
