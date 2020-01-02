# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Adapter do
  let(:adapter) do
    Class.new(OpenTelemetry::Instrumentation::Adapter) do
      adapter_name 'test_adapter'
      adapter_version '0.1.1'
    end
  end

  after do
    OpenTelemetry::Instrumentation.registry.instance_variable_set(:@adapters, [])
  end

  it 'is auto-registered' do
    instance = adapter.instance
    _(OpenTelemetry::Instrumentation.registry.lookup('test_adapter'))
      .must_equal(instance)
  end

  describe '.instance' do
    it 'returns an instance' do
      _(adapter.instance).must_be_instance_of(adapter)
    end
  end

  describe '#adapter_name' do
    it 'returns adapter name' do
      _(adapter.instance.adapter_name).must_equal('test_adapter')
    end
  end

  describe '#adapter_name' do
    it 'returns adapter name' do
      _(adapter.instance.adapter_name).must_equal('test_adapter')
    end
  end
end
