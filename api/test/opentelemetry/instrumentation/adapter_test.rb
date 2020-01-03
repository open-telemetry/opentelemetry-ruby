# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Adapter do
  after do
    OpenTelemetry::Instrumentation.registry.instance_variable_set(:@adapters, [])
  end

  let(:adapter) do
    Class.new(OpenTelemetry::Instrumentation::Adapter) do
      adapter_name 'test_adapter'
      adapter_version '0.1.1'
    end
  end

  let(:adapter_with_callbacks) do
    Class.new(OpenTelemetry::Instrumentation::Adapter) do
      attr_writer :present, :compatible
      attr_reader :present_called, :compatible_called, :install_called,
                  :config_yielded

      adapter_name 'test_adapter'
      adapter_version '0.1.1'

      present do
        @present_called = true
        @present
      end

      compatible do
        @compatible_called = true
        @compatible
      end

      install do |config|
        @config_yielded = config
        @install_called = true
      end

      def initialize(*args)
        super
        @present = true
        @compatible = true
        @present_called = false
        @compatible_called = false
        @install_called = false
      end
    end
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

  describe '#present?' do
    describe 'with present block' do
      it 'calls the present block' do
        instance = adapter_with_callbacks.instance
        _(instance.present?).must_equal(true)
        _(instance.present_called).must_equal(true)
      end
    end

    describe 'without present block' do
      it 'defaults to true' do
        instance = adapter.instance
        _(instance.present?).must_equal(true)
      end
    end
  end

  describe '#compatible?' do
    describe 'with compatible block' do
      it 'calls the compatible block' do
        instance = adapter_with_callbacks.instance
        _(instance.compatible?).must_equal(true)
        _(instance.compatible_called).must_equal(true)
      end
    end

    describe 'without compatible block' do
      it 'defaults to true' do
        instance = adapter.instance
        _(instance.compatible?).must_equal(true)
      end
    end
  end

  describe '#install' do
    describe 'when installable' do
      it 'calls the install block' do
        instance = adapter_with_callbacks.instance
        _(instance.install).must_equal(true)
        _(instance.install_called).must_equal(true)
      end

      it 'yields and set config' do
        instance = adapter_with_callbacks.instance
        config = { option: 'value' }
        instance.install(config)
        _(instance.config_yielded).must_equal(config)
        _(instance.config).must_equal(config)
      end
    end

    describe 'when uninstallable' do
      it 'returns false' do
        instance = adapter_with_callbacks.instance
        instance.compatible = false
        _(instance.install).must_equal(false)
        _(instance.install_called).must_equal(false)
      end
    end

    describe 'without install block defined' do
      it 'returns false' do
        instance = adapter.instance
        _(instance.install).must_equal(false)
      end
    end
  end
end
