# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/exporter/zipkin'

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
    # Reset the logger
    after { OpenTelemetry.logger = Logger.new(File::NULL) }

    it 'returns a logger instance' do
      _(configurator.logger).must_be_instance_of(Logger)
    end

    it 'assigns the logger to OpenTelemetry.logger' do
      custom_logger = Logger.new(File::NULL, level: 'INFO')
      _(OpenTelemetry.logger).wont_equal custom_logger

      OpenTelemetry::SDK.configure { |c| c.logger = custom_logger }
      _(OpenTelemetry.logger.instance_variable_get(:@logger)).must_equal custom_logger
      _(OpenTelemetry.logger).must_be_instance_of(OpenTelemetry::SDK::ForwardingLogger)
    end

    it 'respects the supplied loggers severity level' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        custom_logger = Logger.new(log_stream, level: 'ERROR')
        OpenTelemetry::SDK.configure { |c| c.logger = custom_logger }

        OpenTelemetry.logger.debug('The forwarding logger should forward this message')
        _(log_stream.string).must_be_empty
      end
    end

    it 'allows control of the otel log level' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        custom_logger = Logger.new(log_stream, level: 'DEBUG')

        OpenTelemetry::TestHelpers.with_env('OTEL_LOG_LEVEL' => 'ERROR') do
          OpenTelemetry::SDK.configure { |c| c.logger = custom_logger }
        end

        OpenTelemetry.logger.warn('The forwarding logger should not forward this message')
        _(log_stream.string).must_be_empty
      end
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
        OpenTelemetry::TestHelpers.with_env('OTEL_RESOURCE_ATTRIBUTES' => 'important_value=100') do
          configurator.resource = OpenTelemetry::SDK::Resources::Resource.create('important_value' => '25')
          _(configurator_resource_attributes).must_equal(expected_resource_attributes)
        end
      end

      it 'cleans up whitespace in user provided resources' do
        OpenTelemetry::TestHelpers.with_env('OTEL_RESOURCE_ATTRIBUTES' => ' important_foo=x, important_bar=y ') do
          configurator.resource = OpenTelemetry::SDK::Resources::Resource.create()
          _(configurator_resource_attributes).must_equal(default_resource_attributes.merge('important_foo' => 'x', 'important_bar' => 'y'))
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
        propagator = OpenTelemetry::SDK::Configurator::NoopTextMapPropagator.new
        configurator.propagators = [propagator]
        configurator.configure

        _(OpenTelemetry.propagation).must_equal(propagator)
      end

      it 'can be set by environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_PROPAGATORS' => 'baggage') do
          configurator.configure
        end

        _(OpenTelemetry.propagation).must_equal(OpenTelemetry::Baggage::Propagation.text_map_propagator)
      end

      it 'supports "none" as an environment variable' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_PROPAGATORS' => 'none') do
            configurator.configure
          end

          _(OpenTelemetry.propagation).must_be_instance_of(
            OpenTelemetry::SDK::Configurator::NoopTextMapPropagator
          )

          _(log_stream.string).wont_match(/The none propagator is unknown and cannot be configured/)
        end
      end

      it 'defaults to noop with invalid env var' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_PROPAGATORS' => 'unladen_swallow') do
            configurator.configure
          end

          _(OpenTelemetry.propagation).must_be_instance_of(
            OpenTelemetry::SDK::Configurator::NoopTextMapPropagator
          )

          _(log_stream.string).must_match(/The unladen_swallow propagator is unknown and cannot be configured/)
        end
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
      it 'defaults to no processors if no valid exporter is available' do
        configurator.configure

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)).must_be_empty
      end

      it 'reflects configured value' do
        configurator.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
            OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
          )
        )

        configurator.configure

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors).first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
      end

      it 'can be set by environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'zipkin') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors).first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors).first.instance_variable_get(:@exporter)).must_be_instance_of(
          OpenTelemetry::Exporter::Zipkin::Exporter
        )
      end

      it 'accepts "none" as an environment variable value' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'none') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)).must_be_empty
      end

      it 'accepts comma separated list as an environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'zipkin,console') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[0]).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[0].instance_variable_get(:@exporter)).must_be_instance_of(
          OpenTelemetry::Exporter::Zipkin::Exporter
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[1]).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[1].instance_variable_get(:@span_exporter)).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        )
      end

      it 'accepts comma separated list with preceeding or trailing spaces as an environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'zipkin , console') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[0]).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[0].instance_variable_get(:@exporter)).must_be_instance_of(
          OpenTelemetry::Exporter::Zipkin::Exporter
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[1]).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)[1].instance_variable_get(:@span_exporter)).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        )
      end

      it 'accepts "console" as an environment variable value' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'console') do
          configurator.configure
        end

        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors).first).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
        )
        _(OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors).first.instance_variable_get(:@span_exporter)).must_be_instance_of(
          OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        )
      end

      it 'warns on unsupported otlp transport protocol grpc' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'otlp', 'OTEL_EXPORTER_OTLP_TRACES_PROTOCOL' => 'grpc') do
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            configurator.configure

            _(log_stream.string).must_match(/The grpc transport protocol is not supported by the OTLP exporter/)
          end
        end
      end

      it 'warns on unsupported otlp transport protocol http/json' do
        OpenTelemetry::TestHelpers.with_env('OTEL_TRACES_EXPORTER' => 'otlp', 'OTEL_EXPORTER_OTLP_TRACES_PROTOCOL' => 'http/json') do
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            configurator.configure

            _(log_stream.string).must_match(%r{The http/json transport protocol is not supported by the OTLP exporter})
          end
        end
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
