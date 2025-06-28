# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-exporter-otlp-logs' unless RUBY_ENGINE == 'jruby'

describe OpenTelemetry::SDK::Logs::ConfiguratorPatch do
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

  describe '#configure' do
    describe 'logger_provider' do
      it 'is an instance of SDK::Logs::LoggerProvider' do
        configurator.configure

        _(OpenTelemetry.logger_provider).must_be_instance_of(
          OpenTelemetry::SDK::Logs::LoggerProvider
        )
      end
    end

    describe 'processors' do
      it 'defaults to a batch processor with an otlp exporter' do
        skip 'OTLP exporter not compatible with JRuby' if RUBY_ENGINE == 'jruby'
        configurator.configure

        processors = OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)

        assert_equal 1, processors.size
        processor = processors[0]

        assert_instance_of OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor, processor
        assert_instance_of OpenTelemetry::Exporter::OTLP::Logs::LogsExporter, processor.instance_variable_get(:@exporter)
      end

      it 'can be set by environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'console') do
          configurator.configure
        end

        processors = OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)

        assert_equal 1, processors.size
        processor = processors[0]

        assert_instance_of OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor, processor
        assert_instance_of OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter, processor.instance_variable_get(:@log_record_exporter)
      end

      it 'supports "none" as an environment variable' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'none') do
            configurator.configure
          end

          assert_empty OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)

          refute_match(/The none exporter is unknown and cannot be configured/, log_stream.string)
        end
      end

      it 'supports multiple exporters passed by environment variable' do
        skip 'OTLP exporter not compatible with JRuby' if RUBY_ENGINE == 'jruby'

        OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'console,otlp') do
          configurator.configure
        end

        processors = OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)

        assert_equal 2, processors.size

        processor1 = processors[0]
        processor2 = processors[1]

        assert_instance_of OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor, processor1
        assert_instance_of OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter, processor1.instance_variable_get(:@log_record_exporter)

        assert_instance_of OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor, processor2
        assert_instance_of OpenTelemetry::Exporter::OTLP::Logs::LogsExporter, processor2.instance_variable_get(:@exporter)
      end

      it 'defaults to noop with invalid env var' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'unladen_swallow') do
            configurator.configure
          end

          assert_empty OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)
          assert_match(/The unladen_swallow exporter is unknown and cannot be configured/, log_stream.string)
        end
      end

      it 'rescues NameErrors when otlp set to env var and the library is not installed' do
        if RUBY_ENGINE == 'jruby'
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'otlp') do
              configurator.configure
            end

            assert_empty OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)
            assert_match(/The otlp logs exporter cannot be configured - please add opentelemetry-exporter-otlp-logs to your Gemfile. Logs will not be exported/, log_stream.string)
          end
        else
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.stub(:new, -> { raise NameError }) do
              OpenTelemetry::TestHelpers.with_env('OTEL_LOGS_EXPORTER' => 'otlp') do
                configurator.configure
              end

              assert_empty OpenTelemetry.logger_provider.instance_variable_get(:@log_record_processors)
              assert_match(/The otlp logs exporter cannot be configured - please add opentelemetry-exporter-otlp-logs to your Gemfile. Logs will not be exported/, log_stream.string)
            end
          end
        end
      end
    end
  end
end
