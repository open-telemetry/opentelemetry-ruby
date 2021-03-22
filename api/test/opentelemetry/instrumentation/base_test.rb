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

      option :max_count, default: 5, validate: ->(v) { v.is_a?(Integer) }

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

  describe '.option' do
    let(:instrumentation) do
      Class.new(OpenTelemetry::Instrumentation::Base) do
        instrumentation_name 'test_buggy_instrumentation'
        instrumentation_version '0.0.1'

        option :a, default: 'b', validate: true
      end
    end

    it 'raises argument errors when validate does not receive a callable or valid symbol' do
      _(-> { instrumentation.instance }).must_raise(ArgumentError)
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

      it 'yields and sets config' do
        instance = instrumentation_with_callbacks.instance
        config = { max_count: 3 }

        instance.install(config)
        _(instance.config_yielded).must_equal(config)
        _(instance.config).must_equal(config)
      end

      it 'drops and logs unknown config keys before yielding and setting' do
        instance = instrumentation_with_callbacks.instance
        config = { max_count: 3, unknown_config_option: 500 }
        expected_config = { max_count: 3 }

        mock_logger = Minitest::Mock.new
        mock_logger.expect(:warn, nil, ['Instrumentation test_instrumentation ignored the following unknown configuration options [:unknown_config_option]'])
        OpenTelemetry.stub :logger, mock_logger do
          instance.install(config)
        end
        mock_logger.verify

        _(instance.config_yielded).must_equal(expected_config)
        _(instance.config).must_equal(expected_config)
      end

      it 'uses the default config options when not provided' do
        instance = instrumentation_with_callbacks.instance
        config = {}
        expected_config = { max_count: 5 }

        instance.install(config)
        _(instance.config_yielded).must_equal(expected_config)
        _(instance.config).must_equal(expected_config)
      end

      it 'uses the default config options and logs when validation fails' do
        instance = instrumentation_with_callbacks.instance
        config = { max_count: 'three' }
        expected_config = { max_count: 5 }

        mock_logger = Minitest::Mock.new
        mock_logger.expect(:warn, nil, ['Instrumentation test_instrumentation configuration option max_count value=three failed validation, falling back to default value=5'])
        OpenTelemetry.stub :logger, mock_logger do
          instance.install(config)
        end
        mock_logger.verify

        _(instance.config_yielded).must_equal(expected_config)
        _(instance.config).must_equal(expected_config)
      end

      describe 'when there is an option with a raising validate callable' do
        let(:buggy_instrumentation) do
          Class.new(OpenTelemetry::Instrumentation::Base) do
            instrumentation_name 'test_buggy_instrumentation'
            instrumentation_version '0.0.2'

            present { true }
            compatible { true }
            install { true }

            option :first, default: 'first_default', validate: ->(_v) { raise 'hell' }
            option :second, default: 'second_default', validate: ->(_v) { true }
          end
        end

        it 'falls back to the default' do
          instance = buggy_instrumentation.instance
          instance.install(first: 'value', second: 'user_value')
          _(instance.config).must_equal(first: 'first_default', second: 'user_value')
        end
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
    it 'returns a noop api tracer if not installed' do
      _(instrumentation_with_callbacks.instance.tracer).must_be_instance_of(OpenTelemetry::Trace::Tracer)
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
