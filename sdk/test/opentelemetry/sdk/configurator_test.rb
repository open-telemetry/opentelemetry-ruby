# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/exporter/jaeger'

describe OpenTelemetry::SDK::Configurator do
  let(:configurator) { OpenTelemetry::SDK::Configurator.new }
  let(:default_resource_attributes) do
    {
      'telemetry.sdk.name' => 'opentelemetry',
      'telemetry.sdk.language' => 'ruby',
      'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION,
      'process.pid' => Process.pid,
      'process.command' => $PROGRAM_NAME,
      'process.runtime.name' => RUBY_ENGINE,
      'process.runtime.version' => RUBY_VERSION,
      'process.runtime.description' => RUBY_DESCRIPTION,
      'service.name' => 'unknown_service'
    }
  end

  describe '#logger' do
    it 'returns a logger instance' do
      _(configurator.logger).must_be_instance_of(Logger)
    end
    it 'assigns the logger to OpenTelemetry.logger' do
      custom_logger = Logger.new('/dev/null', level: 'ERROR')
      _(OpenTelemetry.logger).wont_equal custom_logger
      OpenTelemetry::SDK.configure { |c| c.logger = custom_logger }
      _(OpenTelemetry.logger).must_equal custom_logger
    end
  end

  describe '#resource=' do
    let(:configurator_resource) { configurator.instance_variable_get(:@resource) }
    let(:configurator_resource_attributes) { configurator_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { default_resource_attributes.merge('test_key' => 'test_value') }

    it 'merges the resource' do
      configurator.resource = OpenTelemetry::SDK::Resources::Resource.create('test_key' => 'test_value')
      _(configurator_resource_attributes).must_equal(expected_resource_attributes)
    end

    describe 'when there is a resource key collision' do
      let(:expected_resource_attributes) { default_resource_attributes.merge('important_value' => '25') }

      after do
        OpenTelemetry::SDK::Resources::Resource.instance_variable_set(:@default, nil)
      end

      it 'uses the user provided resources' do
        with_env('OTEL_RESOURCE_ATTRIBUTES' => 'important_value=100') do
          configurator.resource = OpenTelemetry::SDK::Resources::Resource.create('important_value' => '25')
          _(configurator_resource_attributes).must_equal(expected_resource_attributes)
        end
      end
    end
  end

  describe '#service_name=' do
    let(:configurator_resource) { configurator.instance_variable_get(:@resource) }
    let(:configurator_resource_attributes) { configurator_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { default_resource_attributes.merge('service.name' => 'Otel Demo App') }

    it 'assigns the service_name resource' do
      configurator.service_name = 'Otel Demo App'
      _(configurator_resource_attributes).must_equal(expected_resource_attributes)
    end
  end

  describe '#service_version=' do
    let(:configurator_resource) { configurator.instance_variable_get(:@resource) }
    let(:configurator_resource_attributes) { configurator_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { default_resource_attributes.merge('service.version' => '0.6.0') }

    it 'assigns the service_version resource' do
      configurator.service_version = '0.6.0'
      _(configurator_resource_attributes).must_equal(expected_resource_attributes)
    end
  end

  describe '#use' do
    it 'can be called multiple times' do
      configurator.use('TestInstrumentation', enabled: true)
      configurator.use('TestInstrumentation1')
    end
  end

  describe '#use, #use_all' do
    describe 'should be used mutually exclusively' do
      it 'raises when use_all called after use' do
        configurator.use('TestInstrumentation', enabled: true)
        _(-> { configurator.use_all }).must_raise(StandardError)
      end

      it 'raises when use called after use_all' do
        configurator.use_all
        _(-> { configurator.use('TestInstrumentation', enabled: true) })
          .must_raise(StandardError)
      end
    end
  end

  describe '#configure' do
    describe 'baggage' do
      it 'is an instance of SDK::Baggage::Manager' do
        configurator.configure

        _(OpenTelemetry.baggage).must_be_instance_of(
          OpenTelemetry::Baggage::Manager
        )
      end
    end

    describe 'propagators' do
      it 'defaults to trace context and baggage' do
        configurator.configure

        expected_propagators = [
          OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator,
          OpenTelemetry::Baggage::Propagation.text_map_propagator
        ]

        _(propagators_for(OpenTelemetry.propagation)).must_equal(expected_propagators)
      end

      it 'is user settable' do
        propagator = OpenTelemetry::Context::Propagation::NoopTextMapPropagator.new
        configurator.propagators = [propagator]
        configurator.configure

        _(OpenTelemetry.propagation).must_equal(propagator)
      end

      it 'can be set by environment variable' do
        with_env('OTEL_PROPAGATORS' => 'baggage') do
          configurator.configure
        end

        _(OpenTelemetry.propagation).must_equal(OpenTelemetry::Baggage::Propagation.text_map_propagator)
      end

      it 'defaults to none with invalid env var' do
        with_env('OTEL_PROPAGATORS' => 'unladen_swallow') do
          configurator.configure
        end

        _(OpenTelemetry.propagation).must_be_instance_of(
          Context::Propagation::NoopTextMapPropagator
        )
      end
    end

    describe 'tracer_provider' do
      it 'is an instance of SDK::Trace::TracerProvider' do
        configurator.configure

        _(OpenTelemetry.tracer_provider).must_be_instance_of(
          OpenTelemetry::SDK::Trace::TracerProvider
        )
      end

      it 'reflects the configured id generator' do
        id_generator = Object.new
        configurator.id_generator = id_generator
        configurator.configure

        _(OpenTelemetry.tracer_provider.id_generator).must_equal id_generator
      end
    end

    describe 'span processors' do
      it 'defaults to NoopSpanProcessor if no valid exporter is available' do
        configurator.configure

        _(OpenTelemetry.tracer_provider.active_span_processor).must_be_instance_of(
          OpenTelemetry::SDK::Trace::NoopSpanProcessor
        )
      end

      it 'reflects configured value' do
        configurator.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
          )
        )

        configurator.configure

        _(OpenTelemetry.tracer_provider.active_span_processor).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
      end

      it 'can be set by environment variable' do
        with_env('OTEL_TRACES_EXPORTER' => 'jaeger') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.active_span_processor).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.active_span_processor.instance_variable_get(:@exporter)).must_be_instance_of(
          OpenTelemetry::Exporter::Jaeger::CollectorExporter
        )
      end

      it 'accepts "none" as an environment variable value' do
        with_env('OTEL_TRACES_EXPORTER' => 'none') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.active_span_processor).must_be_instance_of(
          OpenTelemetry::SDK::Trace::NoopSpanProcessor
        )
      end

      it 'accepts "console" as an environment variable value' do
        with_env('OTEL_TRACES_EXPORTER' => 'console') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.active_span_processor).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.active_span_processor.instance_variable_get(:@span_exporter)).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        )
      end
    end

    describe 'instrumentation installation' do
      before do
        OpenTelemetry::Instrumentation.instance_variable_set(:@registry, nil)
        TestInstrumentation = Class.new(OpenTelemetry::Instrumentation::Base) do
          install { 1 + 1 }
          present { true }
          option :opt, default: false, validate: :boolean
        end
      end

      after do
        Object.send(:remove_const, :TestInstrumentation)
      end

      it 'installs single instrumentation' do
        registry = OpenTelemetry::Instrumentation.registry
        instrumentation = registry.lookup('TestInstrumentation')
        _(instrumentation).wont_be_nil
        _(instrumentation).wont_be(:installed?)
        configurator.use 'TestInstrumentation', opt: true
        configurator.configure
        _(instrumentation).must_be(:installed?)
        _(instrumentation.config).must_equal(opt: true)
      end

      it 'installs all' do
        registry = OpenTelemetry::Instrumentation.registry
        instrumentation = registry.lookup('TestInstrumentation')
        _(instrumentation).wont_be_nil
        _(instrumentation).wont_be(:installed?)
        configurator.use_all 'TestInstrumentation' => { opt: true }
        configurator.configure
        _(instrumentation).must_be(:installed?)
        _(instrumentation.config).must_equal(opt: true)
      end
    end
  end

  def propagators_for(propagator)
    if propagator.instance_of? Context::Propagation::CompositeTextMapPropagator
      propagator.instance_variable_get(:@propagators)
    else
      [propagator]
    end
  end
end
