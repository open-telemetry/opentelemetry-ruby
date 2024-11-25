# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-exporter-otlp-metrics' unless RUBY_ENGINE == 'jruby'

describe OpenTelemetry::SDK::Metrics::ConfiguratorPatch do
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
    describe 'meter_provider' do
      it 'is an instance of SDK::Metrics::MeterProvider' do
        configurator.configure

        _(OpenTelemetry.meter_provider).must_be_instance_of(
          OpenTelemetry::SDK::Metrics::MeterProvider
        )
      end
    end

    describe 'metric readers' do
      it 'defaults to a periodic reader with an otlp exporter' do
        skip 'OTLP exporter not compatible with JRuby' if RUBY_ENGINE == 'jruby'

        configurator.configure

        assert_equal 1, OpenTelemetry.meter_provider.metric_readers.size
        reader = OpenTelemetry.meter_provider.metric_readers[0]

        assert_instance_of OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader, reader
        assert_instance_of OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter, reader.instance_variable_get(:@exporter)
      end

      it 'can be set by environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'console') do
          configurator.configure
        end

        assert_equal 1, OpenTelemetry.meter_provider.metric_readers.size

        reader = OpenTelemetry.meter_provider.metric_readers[0]

        assert_instance_of OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader, reader
        assert_instance_of OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter, reader.instance_variable_get(:@exporter)
      end

      it 'supports "none" as an environment variable' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'none') do
            configurator.configure
          end

          assert_empty OpenTelemetry.meter_provider.metric_readers

          refute_match(/The none exporter is unknown and cannot be configured/, log_stream.string)
        end
      end

      it 'supports multiple exporters passed by environment variable' do
        OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'console,in-memory') do
          configurator.configure
        end

        assert_equal 2, OpenTelemetry.meter_provider.metric_readers.size

        reader1 = OpenTelemetry.meter_provider.metric_readers[0]
        reader2 = OpenTelemetry.meter_provider.metric_readers[1]

        assert_instance_of OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader, reader1
        assert_instance_of OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter, reader1.instance_variable_get(:@exporter)

        assert_instance_of OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter, reader2
      end

      it 'defaults to noop with invalid env var' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'unladen_swallow') do
            configurator.configure
          end

          assert_empty OpenTelemetry.meter_provider.metric_readers
          assert_match(/The unladen_swallow exporter is unknown and cannot be configured/, log_stream.string)
        end
      end

      it 'rescues NameErrors when otlp set to env var and the library is not installed' do
        if RUBY_ENGINE == 'jruby'
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'otlp') do
              configurator.configure
            end

            assert_empty OpenTelemetry.meter_provider.metric_readers
            assert_match(/The otlp metrics exporter cannot be configured - please add opentelemetry-exporter-otlp-metrics to your Gemfile, metrics will not be exported/, log_stream.string)
          end
        else
          OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
            OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.stub(:new, -> { raise NameError }) do
              OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXPORTER' => 'otlp') do
                configurator.configure
              end

              assert_empty OpenTelemetry.meter_provider.metric_readers
              assert_match(/The otlp metrics exporter cannot be configured - please add opentelemetry-exporter-otlp-metrics to your Gemfile, metrics will not be exported/, log_stream.string)
            end
          end
        end
      end
    end
  end
end
