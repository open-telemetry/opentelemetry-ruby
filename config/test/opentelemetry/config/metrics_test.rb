# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Config do
  describe 'meter_provider' do
    after { @sdk&.shutdown }

    # Configures from +yaml+ and keeps the SDK handle for shutdown.
    def configure(yaml)
      with_config(yaml) { |path| @sdk = OpenTelemetry::Config.configure_from_file(path) }
    end

    # Returns the meter provider's registered readers.
    def readers
      @sdk.meter_provider.metric_readers
    end

    it 'is nil when meter_provider is not configured' do
      configure(<<~YAML)
        file_format: "1.0"
        #{TRACER_PROVIDER_YAML}
      YAML

      _(@sdk.meter_provider).must_be_nil
    end

    it 'shares the configured resource' do
      configure(<<~YAML)
        file_format: "1.0"
        resource:
          attributes:
            - name: service.name
              value: metrics-test
        meter_provider:
          readers: []
      YAML

      _(@sdk.meter_provider.resource).must_be_same_as @sdk.resource
    end

    describe 'periodic reader with console exporter' do
      it 'adds a PeriodicMetricReader backed by ConsoleMetricPullExporter' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - periodic:
                  exporter:
                    console: {}
        YAML

        _(@sdk.meter_provider).must_be_instance_of OpenTelemetry::SDK::Metrics::MeterProvider
        _(readers.size).must_equal 1
        _(readers[0]).must_be_instance_of OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader
        _(readers[0].instance_variable_get(:@exporter)).must_be_instance_of OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter
      end

      it 'leaves omitted interval, timeout, and cardinality limit to the SDK' do
        OpenTelemetry::TestHelpers.with_env('OTEL_METRIC_EXPORT_INTERVAL' => '1000',
                                            'OTEL_METRIC_EXPORT_TIMEOUT' => '2000') do
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      console: {}
          YAML
        end

        _(readers[0].instance_variable_get(:@export_interval)).must_equal 1.0
        _(readers[0].instance_variable_get(:@export_timeout)).must_equal 2.0
        _(readers[0].metric_store.instance_variable_get(:@cardinality_limit)).must_be_nil
      end

      it 'forwards interval, timeout, and default cardinality limit to the reader' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - periodic:
                  interval: 5000
                  timeout: 1000
                  cardinality_limits:
                    default: 100
                  exporter:
                    console: {}
        YAML

        _(readers[0].instance_variable_get(:@export_interval)).must_equal 5.0
        _(readers[0].instance_variable_get(:@export_timeout)).must_equal 1.0
        _(readers[0].metric_store.instance_variable_get(:@cardinality_limit)).must_equal 100
      end

      it 'warns that per-instrument-kind cardinality limits are ignored' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    cardinality_limits:
                      counter: 10
                    exporter:
                      console: {}
          YAML

          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: cardinality_limits.counter/)
        end
        _(readers[0].metric_store.instance_variable_get(:@cardinality_limit)).must_be_nil
      end

      it 'warns that producers are ignored' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    producers:
                      - opencensus:
                    exporter:
                      console: {}
          YAML

          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: producers/)
        end
        _(readers.size).must_equal 1
      end

      it 'warns that temporality_preference and default_histogram_aggregation are ignored' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      console:
                        temporality_preference: delta
                        default_histogram_aggregation: base2_exponential_bucket_histogram
          YAML

          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: temporality_preference/)
          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: default_histogram_aggregation/)
        end
        _(readers.size).must_equal 1
      end
    end

    describe 'periodic reader with OTLP HTTP exporter' do
      # Returns the exporter wrapped by the first reader.
      def exporter
        readers[0].instance_variable_get(:@exporter)
      end

      it 'forwards endpoint, headers, compression, and timeout to the exporter' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - periodic:
                  exporter:
                    otlp_http:
                      endpoint: http://collector:4318/v1/metrics
                      headers:
                        - name: api-key
                          value: secret-token
                      compression: gzip
                      timeout: 5000
        YAML

        _(exporter).must_be_instance_of OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter
        _(exporter.instance_variable_get(:@uri).to_s).must_equal 'http://collector:4318/v1/metrics'
        _(exporter.instance_variable_get(:@headers)['api-key']).must_equal 'secret-token'
        _(exporter.instance_variable_get(:@compression)).must_equal 'gzip'
        _(exporter.instance_variable_get(:@timeout)).must_equal 5.0
      end

      it 'parses headers_list when headers is not set' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - periodic:
                  exporter:
                    otlp_http:
                      headers_list: "api-key=secret-token,tenant=acme"
        YAML

        _(exporter.instance_variable_get(:@headers)['api-key']).must_equal 'secret-token'
        _(exporter.instance_variable_get(:@headers)['tenant']).must_equal 'acme'
      end

      it 'leaves omitted options to the exporter' do
        OpenTelemetry::TestHelpers.with_env(
          'OTEL_EXPORTER_OTLP_METRICS_ENDPOINT' => 'http://env-collector:4318/v1/metrics',
          'OTEL_EXPORTER_OTLP_METRICS_COMPRESSION' => 'none',
          'OTEL_EXPORTER_OTLP_METRICS_TIMEOUT' => '3'
        ) do
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      otlp_http: {}
          YAML
        end

        _(exporter.instance_variable_get(:@uri).to_s).must_equal 'http://env-collector:4318/v1/metrics'
        _(exporter.instance_variable_get(:@compression)).must_equal 'none'
        _(exporter.instance_variable_get(:@timeout)).must_equal 3.0
      end

      it 'forwards the TLS CA file to the HTTP client' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - periodic:
                  exporter:
                    otlp_http:
                      endpoint: https://collector:4318/v1/metrics
                      tls:
                        ca_file: /etc/ssl/ca.pem
        YAML

        _(exporter.instance_variable_get(:@http).ca_file).must_equal '/etc/ssl/ca.pem'
      end

      it 'warns that json encoding is ignored' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      otlp_http:
                        encoding: json
          YAML

          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: encoding: json/)
        end
        _(exporter).must_be_instance_of OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter
      end

      it 'warns that temporality_preference is ignored' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      otlp_http:
                        temporality_preference: delta
          YAML

          _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: temporality_preference/)
        end
      end

      it 'skips the reader with a warning when opentelemetry-exporter-otlp-metrics is not loaded' do
        otlp = OpenTelemetry::Exporter::OTLP
        metrics_exporter = otlp.send(:remove_const, :Metrics)

        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      otlp_http: {}
          YAML

          _(log_stream.string).must_match(/otlp_http requires opentelemetry-exporter-otlp-metrics/)
        end
        _(readers).must_be_empty
      ensure
        otlp.const_set(:Metrics, metrics_exporter) if metrics_exporter
      end

      it 'rejects multiple exporters on one reader' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      console: {}
                      otlp_http: {}
          YAML

          _(log_stream.string).must_match(/must not specify multiple exporters/)
        end
        _(readers).must_be_empty
      end
    end

    describe 'unsupported readers and exporters' do
      it 'skips a pull reader with a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - pull:
                    exporter:
                      prometheus/development:
          YAML

          _(log_stream.string).must_match(/pull metric readers are not supported/)
        end
        _(readers).must_be_empty
      end

      it 'skips an otlp_grpc exporter with a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    exporter:
                      otlp_grpc: {}
          YAML

          _(log_stream.string).must_match(/otlp_grpc metric exporter is not supported/)
        end
        _(readers).must_be_empty
      end

      it 'skips a reader without an exporter with a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers:
                - periodic:
                    interval: 1000
          YAML

          _(log_stream.string).must_match(/no exporter config/)
        end
        _(readers).must_be_empty
      end

      it 'keeps valid readers when another reader fails' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            readers:
              - pull:
                  exporter:
                    prometheus/development:
              - periodic:
                  exporter:
                    console: {}
        YAML

        _(readers.size).must_equal 1
      end
    end

    describe 'exemplar_filter' do
      it 'leaves the SDK exemplar filter when exemplar_filter is unset' do
        OpenTelemetry::TestHelpers.with_env('OTEL_METRICS_EXEMPLAR_FILTER' => 'always_on') do
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              readers: []
          YAML
        end

        _(@sdk.meter_provider.exemplar_filter).must_equal OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter
      end

      {
        'always_on' => OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter,
        'always_off' => OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOffExemplarFilter,
        'trace_based' => OpenTelemetry::SDK::Metrics::Exemplar::TraceBasedExemplarFilter
      }.each do |name, filter|
        it "sets the #{name} filter" do
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              exemplar_filter: #{name}
              readers: []
          YAML

          _(@sdk.meter_provider.exemplar_filter).must_equal filter
        end
      end

      it 'warns and leaves the SDK exemplar filter on an unknown filter' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              exemplar_filter: sometimes
              readers: []
          YAML

          _(log_stream.string).must_match(/Unknown exemplar_filter sometimes/)
        end
        _(@sdk.meter_provider.exemplar_filter).must_equal OpenTelemetry::SDK::Metrics::Exemplar::TraceBasedExemplarFilter
      end
    end

    it 'skips with a warning when opentelemetry-metrics-sdk is not loaded' do
      config = OpenTelemetry::Config::Model::MeterProvider.from_hash('readers' => [])
      metrics = OpenTelemetry::Config.const_get(:Metrics)
      sdk_metrics = OpenTelemetry::SDK.send(:remove_const, :Metrics)

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        _(metrics.build_meter_provider(config, nil)).must_be_nil
        _(log_stream.string).must_match(/opentelemetry-metrics-sdk is not loaded/)
      end
    ensure
      OpenTelemetry::SDK.const_set(:Metrics, sdk_metrics) if sdk_metrics
    end
  end
end
