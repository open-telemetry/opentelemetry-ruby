# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config do
  describe 'tracer_provider' do
    describe 'simple processor with console exporter' do
      it 'installs a SimpleSpanProcessor backed by ConsoleSpanExporter' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          tp = OpenTelemetry.tracer_provider

          _(tp).must_be_instance_of OpenTelemetry::SDK::Trace::TracerProvider

          processors = tp.instance_variable_get(:@span_processors)
          _(processors.size).must_equal 1

          _(processors[0]).must_be_instance_of OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
          _(processors[0].instance_variable_get(:@span_exporter)).must_be_instance_of OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        end
      end
    end

    describe 'batch processor with OTLP HTTP exporter' do
      it 'installs a BatchSpanProcessor with the correct endpoint, headers, compression, and timeout' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - batch:
                  schedule_delay: 5000
                  export_timeout: 30000
                  max_queue_size: 2048
                  max_export_batch_size: 512
                  exporter:
                    otlp_http:
                      endpoint: http://localhost:4318/v1/traces
                      headers:
                        - name: api-key
                          value: "secret-token"
                      compression: gzip
                      timeout: 10000
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          processors = OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
          _(processors.size).must_equal 1

          bsp = processors[0]
          _(bsp).must_be_instance_of OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor

          exporter = bsp.instance_variable_get(:@exporter)
          _(exporter).must_be_instance_of OpenTelemetry::Exporter::OTLP::Exporter

          _(exporter.instance_variable_get(:@uri).to_s).must_equal 'http://localhost:4318/v1/traces'
          _(exporter.instance_variable_get(:@compression)).must_equal 'gzip'
          _(exporter.instance_variable_get(:@timeout)).must_equal 10.0
          _(exporter.instance_variable_get(:@headers)['api-key']).must_equal 'secret-token'
        end
      end

      it 'forwards batch tuning parameters to the processor' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - batch:
                  schedule_delay: 3000
                  export_timeout: 15000
                  max_queue_size: 1024
                  max_export_batch_size: 256
                  exporter:
                    otlp_http:
                      endpoint: http://localhost:4318/v1/traces
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          processors = OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
          _(processors.size).must_equal 1

          bsp = processors[0]
          _(bsp.instance_variable_get(:@delay_seconds) * 1000).must_equal 3000.0
          _(bsp.instance_variable_get(:@max_queue_size)).must_equal 1024
          _(bsp.instance_variable_get(:@batch_size)).must_equal 256
        end
      end

      it 'uses declarative defaults instead of OTEL_BSP_* environment variables' do
        OpenTelemetry::TestHelpers.with_env(
          'OTEL_BSP_SCHEDULE_DELAY' => '17',
          'OTEL_BSP_EXPORT_TIMEOUT' => '19',
          'OTEL_BSP_MAX_QUEUE_SIZE' => '23',
          'OTEL_BSP_MAX_EXPORT_BATCH_SIZE' => '7',
          'OTEL_RUBY_BSP_START_THREAD_ON_BOOT' => 'false'
        ) do
          with_config(<<~YAML) do |path|
            file_format: "1.0"
            tracer_provider:
              processors:
                - batch:
                    exporter:
                      console:
          YAML
            sdk = OpenTelemetry::Config.configure_from_file(path)
            processor = sdk.tracer_provider.instance_variable_get(:@span_processors).first

            _(processor.instance_variable_get(:@delay_seconds) * 1000).must_equal 5000.0
            _(processor.instance_variable_get(:@exporter_timeout_seconds) * 1000).must_equal 30_000.0
            _(processor.instance_variable_get(:@max_queue_size)).must_equal 2048
            _(processor.instance_variable_get(:@batch_size)).must_equal 512
            _(processor.instance_variable_get(:@thread)).must_be_instance_of Thread
          end
        end
      end

      it 'uses declarative OTLP defaults instead of OTEL_EXPORTER_OTLP_* environment variables' do
        OpenTelemetry::TestHelpers.with_env(
          'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'http://env.invalid:9999/v1/traces',
          'OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'x-env=present',
          'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION' => 'gzip',
          'OTEL_EXPORTER_OTLP_TRACES_TIMEOUT' => '1234',
          'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => '1'
        ) do
          with_config(<<~YAML) do |path|
            file_format: "1.0"
            tracer_provider:
              processors:
                - batch:
                    exporter:
                      otlp_http: {}
          YAML
            sdk = OpenTelemetry::Config.configure_from_file(path)
            processor = sdk.tracer_provider.instance_variable_get(:@span_processors).first
            exporter = processor.instance_variable_get(:@exporter)

            _(exporter.instance_variable_get(:@uri).to_s).must_equal 'http://localhost:4318/v1/traces'
            _(exporter.instance_variable_get(:@compression)).must_equal 'none'
            _(exporter.instance_variable_get(:@timeout)).must_equal 10.0
            _(exporter.instance_variable_get(:@headers)).wont_include 'x-env'
            _(exporter.instance_variable_get(:@http).verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
          end
        end
      end
    end

    describe 'multiple processors' do
      it 'adds processors in declaration order: batch OTLP first, simple console second' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - batch:
                  exporter:
                    otlp_http:
                      endpoint: http://localhost:4318/v1/traces
              - simple:
                  exporter:
                    console:
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          processors = OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
          _(processors.size).must_equal 2

          _(processors[0]).must_be_instance_of OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor
          _(processors[0].instance_variable_get(:@exporter)).must_be_instance_of OpenTelemetry::Exporter::OTLP::Exporter

          _(processors[1]).must_be_instance_of OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor
          _(processors[1].instance_variable_get(:@span_exporter)).must_be_instance_of OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter
        end
      end
    end

    describe 'sampler configuration' do
      it 'uses ALWAYS_ON when sampler is always_on' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - simple:
                  exporter:
                    console:
            sampler:
              always_on:
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          _(OpenTelemetry.tracer_provider.sampler).must_equal OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON
        end
      end

      it 'uses ALWAYS_OFF when sampler is always_off' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - simple:
                  exporter:
                    console:
            sampler:
              always_off:
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider

          _(OpenTelemetry.tracer_provider.sampler).must_equal OpenTelemetry::SDK::Trace::Samplers::ALWAYS_OFF
        end
      end

      it 'uses TraceIdRatioBased with the configured ratio' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - simple:
                  exporter:
                    console:
            sampler:
              trace_id_ratio_based:
                ratio: 0.25
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          sampler = OpenTelemetry.tracer_provider.sampler

          _(sampler.description).must_match(/0.25/)
        end
      end

      it 'wraps the root sampler in ParentBased' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - simple:
                  exporter:
                    console:
            sampler:
              parent_based:
                root:
                  always_on:
                remote_parent_sampled:
                  always_on:
                remote_parent_not_sampled:
                  always_off:
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          sampler = OpenTelemetry.tracer_provider.sampler

          _(sampler.description).must_match(/ParentBased/)
        end
      end
    end

    describe 'span limits' do
      it 'applies all configured limits to the TracerProvider' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          tracer_provider:
            processors:
              - simple:
                  exporter:
                    console:
            limits:
              attribute_value_length_limit: 512
              attribute_count_limit: 64
              event_count_limit: 32
              link_count_limit: 16
              event_attribute_count_limit: 8
              link_attribute_count_limit: 4
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          OpenTelemetry.tracer_provider = sdk.tracer_provider
          limits = OpenTelemetry.tracer_provider
                                .instance_variable_get(:@span_limits)

          _(limits.attribute_length_limit).must_equal 512
          _(limits.attribute_count_limit).must_equal 64
          _(limits.event_count_limit).must_equal 32
          _(limits.link_count_limit).must_equal 16
          _(limits.event_attribute_count_limit).must_equal 8
          _(limits.link_attribute_count_limit).must_equal 4
        end
      end

      it 'builds schema defaults instead of reusing the SDK environment-backed defaults' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
        YAML
          sdk = OpenTelemetry::Config.configure_from_file(path)
          limits = sdk.tracer_provider.instance_variable_get(:@span_limits)

          _(limits).wont_be_same_as OpenTelemetry::SDK::Trace::SpanLimits::DEFAULT
          _(limits.attribute_count_limit).must_equal 128
          _(limits.attribute_length_limit).must_be_nil
          _(limits.event_count_limit).must_equal 128
          _(limits.link_count_limit).must_equal 128
          _(limits.event_attribute_count_limit).must_equal 128
          _(limits.event_attribute_length_limit).must_be_nil
          _(limits.link_attribute_count_limit).must_equal 128
        end
      end
    end
  end
end
