# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Configurator do
  let(:configurator) { OpenTelemetry::SDK::Configurator.new }

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
    let(:expected_resource_attributes) do
      {
        'telemetry.sdk.name' => 'opentelemetry',
        'telemetry.sdk.language' => 'ruby',
        'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION,
        'test_key' => 'test_value'
      }
    end

    it 'merges the resource' do
      configurator.resource = OpenTelemetry::SDK::Resources::Resource.create('test_key' => 'test_value')
      _(configurator_resource_attributes).must_equal(expected_resource_attributes)
    end

    describe 'when there is a resource key collision' do
      let(:expected_resource_attributes) do
        {
          'telemetry.sdk.name' => 'opentelemetry',
          'telemetry.sdk.language' => 'ruby',
          'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION,
          'important_value' => '25'
        }
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
    let(:expected_resource_attributes) do
      {
        'service.name' => 'Otel Demo App',
        'telemetry.sdk.name' => 'opentelemetry',
        'telemetry.sdk.language' => 'ruby',
        'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION
      }
    end

    it 'assigns the service_name resource' do
      configurator.service_name = 'Otel Demo App'
      _(configurator_resource_attributes).must_equal(expected_resource_attributes)
    end
  end

  describe '#service_version=' do
    let(:configurator_resource) { configurator.instance_variable_get(:@resource) }
    let(:configurator_resource_attributes) { configurator_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) do
      {
        'service.version' => '0.6.0',
        'telemetry.sdk.name' => 'opentelemetry',
        'telemetry.sdk.language' => 'ruby',
        'telemetry.sdk.version' => OpenTelemetry::SDK::VERSION
      }
    end

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
          OpenTelemetry::SDK::Baggage::Manager
        )
      end
    end

    describe 'http_injectors' do
      it 'defaults to trace context and baggage' do
        configurator.configure

        expected_injectors = [
          OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector,
          OpenTelemetry::Baggage::Propagation.text_map_injector
        ]

        _(injectors_for(OpenTelemetry.propagation.http)).must_equal(expected_injectors)
      end

      it 'is user settable' do
        injector = OpenTelemetry::Context::Propagation::NoopInjector.new
        configurator.http_injectors = [injector]
        configurator.configure

        _(injectors_for(OpenTelemetry.propagation.http)).must_equal([injector])
      end
    end

    describe '#http_extractors' do
      it 'defaults to trace context and baggage' do
        configurator.configure

        expected_extractors = [
          OpenTelemetry::Trace::Propagation::TraceContext.rack_extractor,
          OpenTelemetry::Baggage::Propagation.rack_extractor
        ]

        _(extractors_for(OpenTelemetry.propagation.http)).must_equal(expected_extractors)
      end

      it 'is user settable' do
        extractor = OpenTelemetry::Context::Propagation::NoopExtractor.new
        configurator.http_extractors = [extractor]
        configurator.configure

        _(extractors_for(OpenTelemetry.propagation.http)).must_equal([extractor])
      end
    end

    describe 'text_map_injectors' do
      it 'defaults to trace context and baggage' do
        configurator.configure

        expected_injectors = [
          OpenTelemetry::Trace::Propagation::TraceContext.text_map_injector,
          OpenTelemetry::Baggage::Propagation.text_map_injector
        ]

        _(injectors_for(OpenTelemetry.propagation.text)).must_equal(expected_injectors)
      end

      it 'is user settable' do
        injector = OpenTelemetry::Context::Propagation::NoopInjector.new
        configurator.text_map_injectors = [injector]
        configurator.configure

        _(injectors_for(OpenTelemetry.propagation.text)).must_equal([injector])
      end
    end

    describe '#text_map_extractors' do
      it 'defaults to trace context and baggage' do
        configurator.configure

        expected_extractors = [
          OpenTelemetry::Trace::Propagation::TraceContext.text_map_extractor,
          OpenTelemetry::Baggage::Propagation.text_map_extractor
        ]

        _(extractors_for(OpenTelemetry.propagation.text)).must_equal(expected_extractors)
      end

      it 'is user settable' do
        extractor = OpenTelemetry::Context::Propagation::NoopExtractor.new
        configurator.text_map_extractors = [extractor]
        configurator.configure

        _(extractors_for(OpenTelemetry.propagation.text)).must_equal([extractor])
      end
    end

    describe 'tracer_provider' do
      it 'is an instance of SDK::Trace::TracerProvider' do
        configurator.configure

        _(OpenTelemetry.tracer_provider).must_be_instance_of(
          OpenTelemetry::SDK::Trace::TracerProvider
        )
      end
    end

    describe 'span processors' do
      it 'defaults to SimpleSpanProcessor w/ ConsoleSpanExporter' do
        configurator.configure

        processors = active_span_processors

        _(processors.size).must_equal(1)
        _(processors.first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
      end

      it 'reflects configured value' do
        configurator.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            exporter: OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
          )
        )

        configurator.configure
        processors = active_span_processors

        _(processors.size).must_equal(1)
        _(processors.first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
      end
    end

    describe 'instrumentation installation' do
      before do
        OpenTelemetry.instance_variable_set(:@instrumentation_registry, nil)
        TestInstrumentation = Class.new(OpenTelemetry::Instrumentation::Base) do
          install { 1 + 1 }
          present { true }
        end
      end

      after do
        Object.send(:remove_const, :TestInstrumentation)
      end

      it 'installs single instrumentation' do
        registry = OpenTelemetry.instrumentation_registry
        instrumentation = registry.lookup('TestInstrumentation')
        _(instrumentation).wont_be_nil
        _(instrumentation).wont_be(:installed?)
        configurator.use 'TestInstrumentation', opt: true
        configurator.configure
        _(instrumentation).must_be(:installed?)
        _(instrumentation.config).must_equal(opt: true)
      end

      it 'installs all' do
        registry = OpenTelemetry.instrumentation_registry
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

  def active_span_processors
    OpenTelemetry.tracer_provider.active_span_processor.instance_variable_get(:@span_processors)
  end

  def extractors_for(propagator)
    propagator.instance_variable_get(:@extractors) || propagator.instance_variable_get(:@extractor)
  end

  def injectors_for(propagator)
    propagator.instance_variable_get(:@injectors) || propagator.instance_variable_get(:@injector)
  end
end
