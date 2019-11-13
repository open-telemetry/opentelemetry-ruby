# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::DistributedContext::CorrelationContext do
  CorrelationContext = OpenTelemetry::SDK::DistributedContext::CorrelationContext
  Label = OpenTelemetry::DistributedContext::Label
  Key = OpenTelemetry::DistributedContext::Label::Key
  Value = OpenTelemetry::DistributedContext::Label::Value
  Metadata = OpenTelemetry::DistributedContext::Label::Metadata

  let(:foo_key) { Key.new('foo') }
  let(:bar_key) { Key.new('bar') }
  let(:baz_key) { Key.new('baz') }
  let(:foo_label) do
    Label.new(
      key: foo_key,
      value: Value.new('bar')
    )
  end
  let(:bar_label) do
    Label.new(
      key: bar_key,
      value: Value.new('baz')
    )
  end
  let(:baz_label) do
    Label.new(
      key: baz_key,
      value: Value.new('quux')
    )
  end

  describe '.new' do
    it 'does not require any defaults' do
      ctx = CorrelationContext.new
      _(ctx.entries).must_be(:empty?)
    end

    it 'reflects entries passed in' do
      entries = {
        foo_key => foo_label,
        bar_key => bar_label
      }

      ctx = CorrelationContext.new(entries: entries)

      _(ctx.entries).must_equal(entries)
    end

    it 'removes keys specified' do
      entries = {
        foo_key => foo_label,
        bar_key => bar_label
      }

      ctx = CorrelationContext.new(entries: entries, remove_keys: [bar_key])

      _(ctx.entries).must_equal(foo_key => foo_label)
    end

    describe 'with parent' do
      let(:parent_ctx) do
        CorrelationContext.new(entries: { baz_key => baz_label })
      end

      it 'inherits entries' do
        ctx = CorrelationContext.new(parent: parent_ctx)
        _(ctx.entries).must_equal(parent_ctx.entries)
      end

      it 'merges entries' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            foo_key => foo_label,
            bar_key => bar_label
          }
        )
        _(ctx.entries).must_equal(
          foo_key => foo_label,
          bar_key => bar_label,
          baz_key => baz_label
        )
      end

      it 'replaces entries on merge' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            foo_key => foo_label,
            baz_key => bar_label
          }
        )
        _(ctx.entries).must_equal(
          foo_key => foo_label,
          baz_key => bar_label
        )
      end

      it 'removes keys specified' do
        ctx = CorrelationContext.new(
          parent: parent_ctx,
          entries: {
            foo_key => foo_label,
            bar_key => bar_label
          },
          remove_keys: [baz_key]
        )
        _(ctx.entries).must_equal(
          foo_key => foo_label,
          bar_key => bar_label
        )
      end
    end
  end
end
