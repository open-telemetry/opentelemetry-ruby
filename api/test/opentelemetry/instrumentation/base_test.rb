# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Base do
  after do
    OpenTelemetry.instance_variable_set(:@instrumentation_registry, nil)
  end

  let(:instrumentation) do
    Class.new(OpenTelemetry::Instrumentation::Base) do
      instrumentation_name 'test_instrumentation'
      instrumentation_version '0.1.1'
    end
  end

  let(:instrumentation_with_callbacks) do
    Class.new(OpenTelemetry::Instrumentation::Base) do
      attr_writer :present, :compatible
      attr_reader :present_called, :compatible_called, :install_called,
                  :config_yielded

      instrumentation_name 'test_instrumentation'
      instrumentation_version '0.1.1'

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
    instance = instrumentation.instance
    _(OpenTelemetry.instrumentation_registry.lookup('test_instrumentation'))
      .must_equal(instance)
  end

  describe '.instance' do
    it 'returns an instance' do
      _(instrumentation.instance).must_be_instance_of(instrumentation)
    end
  end

  describe '#name' do
    it 'returns instrumentation name' do
      _(instrumentation.instance.name).must_equal('test_instrumentation')
    end
  end

  describe '#version' do
    it 'returns instrumentation version' do
      _(instrumentation.instance.version).must_equal('0.1.1')
    end
  end

  describe '#present?' do
    describe 'with present block' do
      it 'calls the present block' do
        instance = instrumentation_with_callbacks.instance
        _(instance.present?).must_equal(true)
        _(instance.present_called).must_equal(true)
      end
    end

    describe 'without present block' do
      it 'defaults to false' do
        instance = instrumentation.instance
        _(instance.present?).must_equal(false)
      end
    end
  end

  describe '#compatible?' do
    describe 'with compatible block' do
      it 'calls the compatible block' do
        instance = instrumentation_with_callbacks.instance
        _(instance.compatible?).must_equal(true)
        _(instance.compatible_called).must_equal(true)
      end
    end

    describe 'without compatible block' do
      it 'defaults to true' do
        instance = instrumentation.instance
        _(instance.compatible?).must_equal(true)
      end
    end
  end

  describe '#install' do
    describe 'when installable' do
      it 'calls the install block' do
        instance = instrumentation_with_callbacks.instance
        _(instance.install).must_equal(true)
        _(instance.install_called).must_equal(true)
      end

      it 'yields and set config' do
        instance = instrumentation_with_callbacks.instance
        config = { option: 'value' }
        instance.install(config)
        _(instance.config_yielded).must_equal(config)
        _(instance.config).must_equal(config)
      end
    end

    describe 'when uninstallable' do
      it 'returns false' do
        instance = instrumentation_with_callbacks.instance
        instance.compatible = false
        _(instance.install).must_equal(false)
        _(instance.install_called).must_equal(false)
      end
    end

    describe 'without install block defined' do
      it 'returns false' do
        instance = instrumentation.instance
        _(instance.install).must_equal(false)
      end
    end
  end

  describe '#installed?' do
    it 'reflects install state' do
      instance = instrumentation_with_callbacks.instance
      _(instance.installed?).must_equal(false)
      _(instance.install).must_equal(true)
      _(instance.installed?).must_equal(true)
    end
  end

  describe '#enabled?' do
    describe 'with env var' do
      it 'is disabled when false' do
        with_env('TEST_INSTRUMENTATION_ENABLED' => 'false') do
          _(instrumentation.instance.enabled?).must_equal(false)
        end
      end

      it 'is enabled when true' do
        with_env('TEST_INSTRUMENTATION_ENABLED' => 'true') do
          _(instrumentation.instance.enabled?).must_equal(true)
        end
      end

      it 'overrides local config value' do
        with_env('TEST_INSTRUMENTATION_ENABLED' => 'false') do
          instrumentation.instance.enabled?(enabled: true)
          _(instrumentation.instance.enabled?).must_equal(false)
        end
      end

      describe 'local config' do
        it 'is disabled when false' do
          _(instrumentation.instance.enabled?(enabled: false)).must_equal(false)
        end

        it 'is enabled when true' do
          _(instrumentation.instance.enabled?(enabled: true)).must_equal(true)
        end
      end

      describe 'without env var or config' do
        it 'returns true' do
          _(instrumentation.instance.enabled?).must_equal(true)
        end
      end
    end
  end

  describe 'minimal_instrumentation' do
    before do
      MinimalBase = Class.new(OpenTelemetry::Instrumentation::Base)
    end

    after do
      Object.send(:remove_const, :MinimalBase)
    end

    describe '#name' do
      it 'is the class name stringified' do
        _(MinimalBase.instance.name).must_equal('MinimalBase')
      end
    end

    describe '#version' do
      it 'defaults to 0.0.0' do
        _(MinimalBase.instance.version).must_equal('0.0.0')
      end
    end
  end

  describe '#tracer' do
    it 'returns nil if not installed' do
      _(instrumentation_with_callbacks.instance.tracer).must_be_nil
    end

    it 'returns named tracer if installed' do
      instance = instrumentation_with_callbacks.instance
      instance.install
      _(instance.tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
    end
  end

  describe 'namespaced instrumentation' do
    before do
      define_instrumentation_subclass('OTel::Instrumentation::Sinatra::Instrumentation', '2.1.0')
    end

    after do
      Object.send(:remove_const, :OTel)
    end

    describe '#name' do
      it 'defaults to the namespace' do
        instance = OTel::Instrumentation::Sinatra::Instrumentation.instance
        _(instance.name).must_equal('OTel::Instrumentation::Sinatra')
      end
    end

    describe '#version' do
      it 'defaults to the version constant' do
        instance = OTel::Instrumentation::Sinatra::Instrumentation.instance
        _(instance.version).must_equal(OTel::Instrumentation::Sinatra::VERSION)
      end
    end
  end

  def define_instrumentation_subclass(name, version = nil)
    names = name.split('::').map(&:to_sym)
    names.inject(Object) do |object, const|
      if const == names[-1]
        object.const_set(:VERSION, version) if version
        object.const_set(const, Class.new(OpenTelemetry::Instrumentation::Base))
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
