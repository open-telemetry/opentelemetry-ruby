# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/adapters/rack'
require_relative '../../../../../lib/opentelemetry/adapters/rack/patches/rack_builder'

describe OpenTelemetry::Adapters::Rack::Patches::RackBuilder do
  let(:adapter_module) { OpenTelemetry::Adapters::Rack }
  let(:adapter_class) { adapter_module::Adapter }
  let(:adapter) { adapter_class.instance }

  let(:config) { {} }

  before do
    # allow for adapter re-installation:
    adapter.instance_variable_set('@installed', false)
  end

  describe 'default installation' do
    it 'adds middleware to default stack' do
      _(::Rack::Builder.new.instance_variable_get(:@use).length).must_equal 0

      adapter.install(config)

      _(::Rack::Builder.new.instance_variable_get(:@use).length).must_equal 1
    end
  end
end
