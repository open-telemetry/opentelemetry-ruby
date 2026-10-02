# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config do
  describe 'logger_provider' do
    after { @sdk&.shutdown }

    # Configures from +yaml+ and keeps the SDK handle for shutdown.
    def configure(yaml)
      with_config(yaml) { |path| @sdk = OpenTelemetry::Config.configure_from_file(path) }
    end

    # Returns the logger provider's registered processors.
    def processors
      @sdk.logger_provider.instance_variable_get(:@log_record_processors)
    end

    it 'is nil when logger_provider is not configured' do
      configure(<<~YAML)
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
      YAML

      _(@sdk.logger_provider).must_be_nil
    end

    it 'shares the configured resource' do
      configure(<<~YAML)
        file_format: "1.0"
        resource:
          attributes:
            - name: service.name
              value: logs-test
        logger_provider:
          processors:
            - simple:
                exporter:
                  console:
      YAML

      _(@sdk.logger_provider.instance_variable_get(:@resource)).must_be_same_as @sdk.resource
    end

    describe 'simple processor with console exporter' do
      it 'adds a SimpleLogRecordProcessor backed by ConsoleLogRecordExporter' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - simple:
                  exporter:
                    console:
        YAML

        _(@sdk.logger_provider).must_be_instance_of OpenTelemetry::SDK::Logs::LoggerProvider
        _(processors.size).must_equal 1
        _(processors[0]).must_be_instance_of OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor
        _(processors[0].instance_variable_get(:@log_record_exporter)).must_be_instance_of OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter
      end
    end

    describe 'batch processor' do
      it 'forwards batch tuning parameters to the processor' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - batch:
                  schedule_delay: 3000
                  export_timeout: 15000
                  max_queue_size: 1024
                  max_export_batch_size: 256
                  exporter:
                    console:
        YAML

        blrp = processors[0]
        _(blrp).must_be_instance_of OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor
        _(blrp.instance_variable_get(:@delay_seconds)).must_equal 3.0
        _(blrp.instance_variable_get(:@exporter_timeout_seconds)).must_equal 15.0
        _(blrp.instance_variable_get(:@max_queue_size)).must_equal 1024
        _(blrp.instance_variable_get(:@batch_size)).must_equal 256
      end
    end

    describe 'OTLP HTTP exporter' do
      it 'builds a LogsExporter with the correct endpoint, headers, compression, and timeout' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - batch:
                  exporter:
                    otlp_http:
                      endpoint: http://localhost:4318/v1/logs
                      headers:
                        - name: api-key
                          value: "secret-token"
                      compression: gzip
                      timeout: 10000
        YAML

        exporter = processors[0].instance_variable_get(:@exporter)
        _(exporter).must_be_instance_of OpenTelemetry::Exporter::OTLP::Logs::LogsExporter
        _(exporter.instance_variable_get(:@uri).to_s).must_equal 'http://localhost:4318/v1/logs'
        _(exporter.instance_variable_get(:@compression)).must_equal 'gzip'
        _(exporter.instance_variable_get(:@timeout)).must_equal 10.0
        _(exporter.instance_variable_get(:@headers)['api-key']).must_equal 'secret-token'
      end

      it 'parses headers_list when headers is not set' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - simple:
                  exporter:
                    otlp_http:
                      headers_list: "api-key=secret-token,tenant=acme"
        YAML

        headers = processors[0].instance_variable_get(:@log_record_exporter).instance_variable_get(:@headers)
        _(headers['api-key']).must_equal 'secret-token'
        _(headers['tenant']).must_equal 'acme'
      end
    end

    describe 'multiple processors' do
      it 'adds every configured processor in order' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - simple:
                  exporter:
                    console:
              - batch:
                  exporter:
                    console:
        YAML

        _(processors.map(&:class)).must_equal [
          OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor,
          OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor
        ]
      end
    end

    describe 'invalid processors' do
      it 'skips a processor that sets both batch and simple' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - batch:
                  exporter:
                    console:
                simple:
                  exporter:
                    console:
        YAML

        _(processors).must_be_empty
      end

      it 'skips a processor with no exporter' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - simple: {}
        YAML

        _(processors).must_be_empty
      end

      it 'skips a processor with an unsupported exporter' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            processors:
              - simple:
                  exporter:
                    otlp_file/development: {}
        YAML

        _(processors).must_be_empty
      end
    end

    describe 'limits' do
      it 'forwards configured limits' do
        configure(<<~YAML)
          file_format: "1.0"
          logger_provider:
            limits:
              attribute_count_limit: 10
              attribute_value_length_limit: 64
        YAML

        limits = @sdk.logger_provider.instance_variable_get(:@log_record_limits)
        _(limits.attribute_count_limit).must_equal 10
        _(limits.attribute_length_limit).must_equal 64
      end
    end
  end
end
