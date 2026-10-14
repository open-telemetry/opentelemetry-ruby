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

    describe 'views' do
      # Returns the meter provider's registered views.
      def views
        @sdk.meter_provider.registered_views
      end

      # Attaches an in-memory reader, runs the block against a meter, and
      # returns the pulled metric snapshots.
      def record
        reader = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
        @sdk.meter_provider.add_metric_reader(reader)
        yield @sdk.meter_provider.meter('test-meter')
        reader.pull
        reader.metric_snapshots
      end

      it 'registers a view with selector criteria and cardinality limit' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: http.*
                  instrument_type: histogram
                  unit: ms
                  meter_name: my-meter
                  meter_version: 1.0.0
                stream:
                  aggregation:
                    drop: {}
                  aggregation_cardinality_limit: 50
        YAML

        _(views.size).must_equal 1
        view = views[0]
        _(view.name).must_equal 'http.*'
        _(view.aggregation).must_be_instance_of OpenTelemetry::SDK::Metrics::Aggregation::Drop
        _(view.aggregation_cardinality_limit).must_equal 50
        options = view.instance_variable_get(:@options)
        _(options.slice(:type, :unit, :meter_name, :meter_version))
          .must_equal(type: :histogram, unit: 'ms', meter_name: 'my-meter', meter_version: '1.0.0')
      end

      it 'builds explicit bucket histogram aggregations with boundaries' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: latency
                stream:
                  aggregation:
                    explicit_bucket_histogram:
                      boundaries: [10, 1, 100]
                      record_min_max: false
        YAML

        aggregation = views[0].aggregation
        _(aggregation).must_be_instance_of OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram
        _(aggregation.instance_variable_get(:@boundaries)).must_equal [1, 10, 100]
        _(aggregation.instance_variable_get(:@record_min_max)).must_equal false
      end

      it 'builds base2 exponential bucket histogram aggregations' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: latency
                stream:
                  aggregation:
                    base2_exponential_bucket_histogram:
                      max_scale: 10
                      max_size: 80
        YAML

        aggregation = views[0].aggregation
        _(aggregation).must_be_instance_of OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram
        _(aggregation.instance_variable_get(:@scale)).must_equal 10
        _(aggregation.instance_variable_get(:@size)).must_equal 80
      end

      it 'builds last_value aggregations' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: temperature
                stream:
                  aggregation:
                    last_value: {}
        YAML

        _(views[0].aggregation).must_be_instance_of OpenTelemetry::SDK::Metrics::Aggregation::LastValue
      end

      it 'derives sum monotonicity from the instrument type' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_type: counter
                stream:
                  aggregation:
                    sum: {}
              - selector:
                  instrument_type: up_down_counter
                stream:
                  aggregation:
                    sum: {}
        YAML

        _(views[0].aggregation.monotonic?).must_equal true
        _(views[1].aggregation.monotonic?).must_equal false
      end

      it 'resolves the default aggregation from the instrument type' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: requests
                  instrument_type: counter
                stream:
                  aggregation_cardinality_limit: 1
        YAML

        snapshots = record do |meter|
          counter = meter.create_counter('requests')
          counter.add(1, attributes: { 'route' => '/a' })
          counter.add(2, attributes: { 'route' => '/b' })
        end

        _(views[0].aggregation).must_be_instance_of OpenTelemetry::SDK::Metrics::Aggregation::Sum
        _(snapshots.size).must_equal 1
        _(snapshots[0].data_points.sum(&:value)).must_equal 3
        _(snapshots[0].data_points.map(&:attributes)).must_include('otel.metric.overflow' => true)
      end

      it 'discards measurements for a drop view' do
        configure(<<~YAML)
          file_format: "1.0"
          meter_provider:
            views:
              - selector:
                  instrument_name: noisy
                stream:
                  aggregation:
                    drop: {}
        YAML

        snapshots = record do |meter|
          meter.create_counter('noisy').add(5)
          meter.create_counter('kept').add(5)
        end

        noisy, kept = snapshots.partition { |m| m.name == 'noisy' }.map(&:first)
        _(noisy.data_points.map(&:value)).must_equal [0]
        _(kept.data_points.map(&:value)).must_equal [5]
      end

      it 'skips a view with default aggregation and no instrument type with a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              views:
                - selector:
                    instrument_name: requests
                  stream:
                    aggregation:
                      default: {}
          YAML

          _(log_stream.string).must_match(/default aggregation requires selector.instrument_type/)
        end
        _(views).must_be_empty
      end

      it 'skips a view with an unknown instrument type with a warning' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              views:
                - selector:
                    instrument_type: timer
                  stream:
                    aggregation:
                      drop: {}
          YAML

          _(log_stream.string).must_match(/unknown instrument_type timer/)
        end
        _(views).must_be_empty
      end

      it 'warns about unsupported selector and stream settings and keeps the view' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          configure(<<~YAML)
            file_format: "1.0"
            meter_provider:
              views:
                - selector:
                    instrument_name: requests
                    meter_schema_url: https://example.com/schema
                  stream:
                    name: renamed
                    description: renamed description
                    attribute_keys:
                      included: [route]
                    aggregation:
                      drop: {}
          YAML

          %w[selector.meter_schema_url stream.name stream.description stream.attribute_keys].each do |setting|
            _(log_stream.string).must_match(/Ignoring unsupported meter_provider setting: #{Regexp.escape(setting)}/)
          end
        end
        _(views.size).must_equal 1
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
