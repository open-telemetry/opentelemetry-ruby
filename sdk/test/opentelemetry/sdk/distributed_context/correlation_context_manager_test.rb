# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::DistributedContext::CorrelationContext do
  CorrelationContext = OpenTelemetry::SDK::DistributedContext::CorrelationContext
  Label = OpenTelemetry::DistributedContext::Label

  let(:manager) do
    OpenTelemetry::SDK::DistributedContext::CorrelationContextManager.new
  end

  after do
    OpenTelemetry::Context.clear
  end

  let(:foo_label) { Label.new(key: 'foo', value: 'bar') }
  let(:bar_label) { Label.new(key: 'bar', value: 'baz') }
  let(:baz_label) { Label.new(key: 'baz', value: 'quux') }

  describe '#create_context' do
    it 'returned context reflects entries passed in' do
      ctx = manager.create_context(labels: [foo_label, bar_label])
      _(ctx.entries).must_equal('foo' => foo_label, 'bar' => bar_label)
    end

    it 'returned context removes keys specified' do
      ctx = manager.create_context(labels: [foo_label, bar_label],
                                   remove_keys: ['foo'])
      _(ctx.entries).must_equal('bar' => bar_label)
    end

    describe 'with parent' do
      let(:parent_ctx) do
        manager.create_context(labels: [foo_label, bar_label])
      end

      it 'returned context inherits entries' do
        child_ctx = manager.create_context(labels: [baz_label],
                                           parent: parent_ctx)

        _(child_ctx.entries).must_equal('foo' => foo_label,
                                        'bar' => bar_label,
                                        'baz' => baz_label)
      end

      it 'returned context removes keys specified' do
        child_ctx = manager.create_context(labels: [baz_label],
                                           remove_keys: ['foo'],
                                           parent: parent_ctx)

        _(child_ctx.entries).must_equal('bar' => bar_label,
                                        'baz' => baz_label)
      end
    end
  end
end
