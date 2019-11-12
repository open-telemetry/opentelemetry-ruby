# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::DistributedContext::CorrelationContextManager do
  CorrelationContext = OpenTelemetry::DistributedContext::CorrelationContext
  let(:manager) { OpenTelemetry::DistributedContext::CorrelationContextManager.new }

  after do
    Context.clear
  end

  describe '#current_context' do
    it 'returns an empty context by default' do
      ctx = manager.current_context
      _(ctx).must_be_instance_of(CorrelationContext)
      _(ctx.entries).must_be(:empty?)
    end
  end

  describe '#with_current_context' do
    it 'handles nested contexts' do
      c1 = CorrelationContext.new
      manager.with_current_context(c1) do
        _(manager.current_context).must_equal(c1)
        c2 = CorrelationContext.new
        manager.with_current_context(c2) do
          _(manager.current_context).must_equal(c2)
        end
        _(manager.current_context).must_equal(c1)
      end
    end
  end

  describe '#create_context' do
    it 'returns an empty context' do
      ctx = manager.create_context
      _(ctx).must_be_instance_of(CorrelationContext)
      _(ctx.entries).must_be(:empty?)
    end
  end
end
