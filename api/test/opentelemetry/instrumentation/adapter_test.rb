# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Adapter do
  after do
    OpenTelemetry.instance_variable_set(:@instrumentation_registry, nil)
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
    _(OpenTelemetry.instrumentation_registry.lookup('test_adapter'))
      .must_equal(instance)
  end

  describe '.instance' do
    it 'returns an instance' do
      _(adapter.instance).must_be_instance_of(adapter)
    end
  end

  describe '#name' do
    it 'returns adapter name' do
      _(adapter.instance.name).must_equal('test_adapter')
    end
  end

  describe '#version' do
    it 'returns adapter version' do
      _(adapter.instance.version).must_equal('0.1.1')
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

  describe '#installed?' do
    it 'reflects install state' do
      instance = adapter_with_callbacks.instance
      _(instance.installed?).must_equal(false)
      _(instance.install).must_equal(true)
      _(instance.installed?).must_equal(true)
    end
  end

  describe '#enabled?' do
    describe 'with env var' do
      it 'is disabled when false' do
        with_env('TEST_ADAPTER_ENABLED' => 'false') do
          _(adapter.instance.enabled?).must_equal(false)
        end
      end

      it 'is enabled when true' do
        with_env('TEST_ADAPTER_ENABLED' => 'true') do
          _(adapter.instance.enabled?).must_equal(true)
        end
      end

      it 'overrides local config value' do
        with_env('TEST_ADAPTER_ENABLED' => 'false') do
          adapter.instance.enabled?(enabled: true)
          _(adapter.instance.enabled?).must_equal(false)
        end
      end

      describe 'local config' do
        it 'is disabled when false' do
          _(adapter.instance.enabled?(enabled: false)).must_equal(false)
        end

        it 'is enabled when true' do
          _(adapter.instance.enabled?(enabled: true)).must_equal(true)
        end
      end

      describe 'without env var or config' do
        it 'returns true' do
          _(adapter.instance.enabled?).must_equal(true)
        end
      end
    end
  end

  describe 'minimal_adapter' do
    before do
      MinimalAdapter = Class.new(OpenTelemetry::Instrumentation::Adapter)
    end

    after do
      Object.send(:remove_const, :MinimalAdapter)
    end

    describe '#name' do
      it 'is the class name stringified' do
        _(MinimalAdapter.instance.name).must_equal('MinimalAdapter')
      end
    end

    describe '#version' do
      it 'defaults to 0.0.0' do
        _(MinimalAdapter.instance.version).must_equal('0.0.0')
      end
    end
  end

  describe '#tracer' do
    it 'returns nil if not installed' do
      _(adapter_with_callbacks.instance.tracer).must_be_nil
    end

    it 'returns named tracer if installed' do
      instance = adapter_with_callbacks.instance
      instance.install
      _(instance.tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end
  end

  describe 'namespaced adapter' do
    before do
      define_adapter_subclass('OTel::Adapters::Sinatra::Adapter', '2.1.0')
    end

    after do
      Object.send(:remove_const, :OTel)
    end

    describe '#name' do
      it 'defaults to the namespace' do
        instance = OTel::Adapters::Sinatra::Adapter.instance
        _(instance.name).must_equal('OTel::Adapters::Sinatra')
      end
    end

    describe '#version' do
      it 'defaults to the version constant' do
        instance = OTel::Adapters::Sinatra::Adapter.instance
        _(instance.version).must_equal(OTel::Adapters::Sinatra::VERSION)
      end
    end
  end

  def define_adapter_subclass(name, version = nil)
    names = name.split('::').map(&:to_sym)
    names.inject(Object) do |object, const|
      if const == names[-1]
        object.const_set(:VERSION, version) if version
        object.const_set(const, Class.new(OpenTelemetry::Instrumentation::Adapter))
      else
        object.const_set(const, Module.new)
      end
    end
  end

  def with_env(new_env)
    env_to_reset = ENV.select { |k, _| new_env.key?(k) }
    keys_to_delete = new_env.keys - ENV.keys
    new_env.each_pair { |k, v| ENV[k] = v }
    yield
    env_to_reset.each_pair { |k, v| ENV[k] = v }
    keys_to_delete.each { |k| ENV.delete(k) }
  end
end
