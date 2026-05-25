# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::OtelConfig do
  describe 'tracer_provider' do
    describe 'simple processor with console exporter' do
      it 'installs a SimpleSpanProcessor backed by ConsoleSpanExporter' do
        with_config(<<~YAML) do |path|
          file_format: "1.0"
          #{TRACER_PROVIDER_YAML}
        YAML
          OpenTelemetry::OtelConfig.configure_from_file(path)
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
          OpenTelemetry::OtelConfig.configure_from_file(path)

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
          OpenTelemetry::OtelConfig.configure_from_file(path)

          processors = OpenTelemetry.tracer_provider.instance_variable_get(:@span_processors)
          _(processors.size).must_equal 1

          bsp = processors[0]
          _(bsp.instance_variable_get(:@delay_seconds) * 1000).must_equal 3000.0
          _(bsp.instance_variable_get(:@max_queue_size)).must_equal 1024
          _(bsp.instance_variable_get(:@batch_size)).must_equal 256
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
          OpenTelemetry::OtelConfig.configure_from_file(path)

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
          OpenTelemetry::OtelConfig.configure_from_file(path)

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
          OpenTelemetry::OtelConfig.configure_from_file(path)

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
          OpenTelemetry::OtelConfig.configure_from_file(path)
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
          OpenTelemetry::OtelConfig.configure_from_file(path)
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
          OpenTelemetry::OtelConfig.configure_from_file(path)
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
    end
  end
end
