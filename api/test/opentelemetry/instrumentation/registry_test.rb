# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Registry do
  let(:registry) do
    OpenTelemetry::Instrumentation::Registry.new
  end

  let(:adapter) do
    Class.new(OpenTelemetry::Instrumentation::Adapter) do
      adapter_name 'test_adapter'
      adapter_version '0.1.1'
    end
  end

  after do
    OpenTelemetry::Instrumentation.registry.instance_variable_set(:@adapters, [])
  end

  describe '#register, #lookup' do
    it 'registers and looks up adapters' do
      registry.register(adapter)
      _(registry.lookup(adapter.instance.adapter_name)).must_equal(adapter.instance)
    end
  end
end
