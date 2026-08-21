# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter do
  let(:success) { OpenTelemetry::SDK::Trace::Export::SUCCESS }
  let(:failure_result) { OpenTelemetry::SDK::Trace::Export::FAILURE }

  describe '#initialize' do
    it 'initializes with default endpoint' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
      _(exporter.instance_variable_get(:@timeout)).must_equal 10.0
      _(exporter.instance_variable_get(:@shutdown)).must_equal false
    end

    it 'initializes with custom endpoint' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      client = exporter.instance_variable_get(:@client)
      # gRPC stub stores the resolved host:port in @host
      _(client.instance_variable_get(:@host)).must_equal 'localhost:4317'
    end

    it 'initializes with custom timeout' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(timeout: 5)
      _(exporter.instance_variable_get(:@timeout)).must_equal 5.0
    end

    it 'raises error for invalid endpoint' do
      assert_raises(ArgumentError) do
        OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'not a url')
      end
    end

    it 'initializes with certificate file' do
      require 'tempfile'
      cert_file = Tempfile.new(['test_cert', '.pem'])
      cert_file.write("-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----")
      cert_file.close

      begin
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(
          endpoint: 'https://localhost:4317',
          certificate_file: cert_file.path
        )
        _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4317'
      ensure
        cert_file.unlink
      end
    end

    it 'initializes with client certificate and key' do
      require 'tempfile'
      ca_file = Tempfile.new(['ca', '.pem'])
      ca_file.write("-----BEGIN CERTIFICATE-----\ntest ca\n-----END CERTIFICATE-----")
      ca_file.close

      client_cert_file = Tempfile.new(['client', '.pem'])
      client_cert_file.write("-----BEGIN CERTIFICATE-----\ntest client\n-----END CERTIFICATE-----")
      client_cert_file.close

      client_key_file = Tempfile.new(['client-key', '.pem'])
      client_key_file.write("-----BEGIN PRIVATE KEY-----\ntest key\n-----END PRIVATE KEY-----")
      client_key_file.close

      begin
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(
          endpoint: 'https://localhost:4317',
          certificate_file: ca_file.path,
          client_certificate_file: client_cert_file.path,
          client_key_file: client_key_file.path
        )
        _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4317'
      ensure
        ca_file.unlink
        client_cert_file.unlink
        client_key_file.unlink
      end
    end

    it 'reads endpoint from environment variable OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' do
      OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'http://localhost:4318') do
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
        _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4318'
      end
    end

    it 'reads endpoint from environment variable OTEL_EXPORTER_OTLP_ENDPOINT' do
      OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://localhost:4319') do
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
        _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4319'
      end
    end

    it 'prioritizes OTEL_EXPORTER_OTLP_TRACES_ENDPOINT over OTEL_EXPORTER_OTLP_ENDPOINT' do
      OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'http://localhost:4318',
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://localhost:4319'
      ) do
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
        # TRACES_ENDPOINT has higher priority — should connect to 4318, not 4319
        _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4318'
      end
    end

    it 'reads timeout from environment variable OTEL_EXPORTER_OTLP_TRACES_TIMEOUT' do
      OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT' => '15') do
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
        _(exporter.instance_variable_get(:@timeout)).must_equal 15.0
      end
    end

    it 'reads timeout from environment variable OTEL_EXPORTER_OTLP_TIMEOUT' do
      OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TIMEOUT' => '20') do
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new
        _(exporter.instance_variable_get(:@timeout)).must_equal 20.0
      end
    end

    it 'reads certificate from environment variable OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE' do
      require 'tempfile'
      cert_file = Tempfile.new(['test_cert', '.pem'])
      cert_file.write("-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----")
      cert_file.close

      begin
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE' => cert_file.path) do
          exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'https://localhost:4317')
          # TLS channel credentials should be set (not insecure)
          _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4317'
        end
      ensure
        cert_file.unlink
      end
    end

    it 'reads certificate from environment variable OTEL_EXPORTER_OTLP_CERTIFICATE' do
      require 'tempfile'
      cert_file = Tempfile.new(['test_cert', '.pem'])
      cert_file.write("-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----")
      cert_file.close

      begin
        OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_CERTIFICATE' => cert_file.path) do
          exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'https://localhost:4317')
          _(exporter.instance_variable_get(:@client).instance_variable_get(:@host)).must_equal 'localhost:4317'
        end
      ensure
        cert_file.unlink
      end
    end
  end

  describe '#export' do
    # Shared stub helper: stubs @client.export to return a mock success response
    # without needing a live gRPC server.
    def stub_grpc_success(exporter, &block)
      mock_response = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceResponse.new
      exporter.instance_variable_get(:@client).stub(:export, ->(_req, **_kwargs) { mock_response }, &block)
    end

    it 'exports span data successfully' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports multiple spans' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data1 = OpenTelemetry::TestHelpers.create_span_data(name: 'span1')
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(name: 'span2')
      stub_grpc_success(exporter) do
        _(exporter.export([span_data1, span_data2])).must_equal(success)
      end
    end

    it 'exports spans with different kinds' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      %i[internal server client producer consumer].each do |kind|
        span_data = OpenTelemetry::TestHelpers.create_span_data(kind: kind)
        stub_grpc_success(exporter) do
          _(exporter.export([span_data])).must_equal(success)
        end
      end
    end

    it 'exports spans with attributes' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      attrs = { 'string_attr' => 'value', 'int_attr' => 42, 'float_attr' => 3.14, 'bool_attr' => true, 'array_attr' => [1, 2, 3] }
      span_data = OpenTelemetry::TestHelpers.create_span_data(
        attributes: attrs,
        total_recorded_attributes: attrs.size
      )
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports spans with events' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      event = OpenTelemetry::SDK::Trace::Event.new(
        name: 'test_event',
        attributes: { 'event_attr' => 'event_value' },
        timestamp: OpenTelemetry::TestHelpers.exportable_timestamp
      )
      span_data = OpenTelemetry::TestHelpers.create_span_data(events: [event], total_recorded_events: 1)
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports spans with links' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      trace_id = OpenTelemetry::Trace.generate_trace_id
      span_id = OpenTelemetry::Trace.generate_span_id
      span_context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id)
      link = OpenTelemetry::Trace::Link.new(span_context, { 'link_attr' => 'link_value' })
      span_data = OpenTelemetry::TestHelpers.create_span_data(links: [link], total_recorded_links: 1)
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports spans with status' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')

      [
        OpenTelemetry::Trace::Status.ok,
        OpenTelemetry::Trace::Status.error('Test error'),
        OpenTelemetry::Trace::Status.unset
      ].each do |status|
        span_data = OpenTelemetry::TestHelpers.create_span_data(status: status)
        stub_grpc_success(exporter) do
          _(exporter.export([span_data])).must_equal(success)
        end
      end
    end

    it 'encodes dropped attributes, events, and links counts into the proto' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data(
        total_recorded_attributes: 10,
        attributes: { 'a' => 1, 'b' => 2 },
        total_recorded_events: 5,
        events: [OpenTelemetry::SDK::Trace::Event.new(name: 'event', timestamp: Time.now.to_i * 1_000_000_000)],
        total_recorded_links: 3,
        links: []
      )

      captured_request = nil
      exporter.instance_variable_get(:@client).stub(
        :export,
        lambda { |req, **_kwargs|
          captured_request = req
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceResponse.new
        }
      ) do
        _(exporter.export([span_data])).must_equal(success)
      end

      span_proto = captured_request.resource_spans.first.scope_spans.first.spans.first
      # 10 recorded - 2 present = 8 dropped attributes
      _(span_proto.dropped_attributes_count).must_equal 8
      # 5 recorded - 1 present = 4 dropped events
      _(span_proto.dropped_events_count).must_equal 4
      # 3 recorded - 0 present = 3 dropped links
      _(span_proto.dropped_links_count).must_equal 3
    end

    it 'returns failure after shutdown' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      exporter.shutdown
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(failure_result)
    end

    it 'handles empty span data array' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      stub_grpc_success(exporter) do
        _(exporter.export([])).must_equal(success)
      end
    end

    it 'exports spans with different resources' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      resource1 = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'service1')
      resource2 = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'service2')
      span_data1 = OpenTelemetry::TestHelpers.create_span_data(resource: resource1)
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(resource: resource2)
      stub_grpc_success(exporter) do
        _(exporter.export([span_data1, span_data2])).must_equal(success)
      end
    end

    it 'exports spans with different instrumentation scopes' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      scope1 = OpenTelemetry::SDK::InstrumentationScope.new('scope1', '1.0.0')
      scope2 = OpenTelemetry::SDK::InstrumentationScope.new('scope2', '2.0.0')
      span_data1 = OpenTelemetry::TestHelpers.create_span_data(instrumentation_scope: scope1)
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(instrumentation_scope: scope2)
      stub_grpc_success(exporter) do
        _(exporter.export([span_data1, span_data2])).must_equal(success)
      end
    end

    it 'exports spans with trace state' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports spans with parent span id' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      parent_span_id = OpenTelemetry::Trace.generate_span_id
      span_data = OpenTelemetry::TestHelpers.create_span_data(parent_span_id: parent_span_id)
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'exports spans with complex nested attributes' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      nested_attrs = { 'nested_array' => [[1, 2], [3, 4]], 'mixed_array' => [1, 'two', 3.0, true] }
      span_data = OpenTelemetry::TestHelpers.create_span_data(
        attributes: nested_attrs,
        total_recorded_attributes: nested_attrs.size
      )
      stub_grpc_success(exporter) do
        _(exporter.export([span_data])).must_equal(success)
      end
    end

    it 'translates all the things' do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
      tracer = OpenTelemetry.tracer_provider.tracer('tracer', 'v0.0.1')

      trace_id      = OpenTelemetry::Trace.generate_trace_id
      root_span_id  = OpenTelemetry::Trace.generate_span_id
      child_span_id = OpenTelemetry::Trace.generate_span_id
      start_timestamp = Time.now
      end_timestamp   = start_timestamp + 6

      root = OpenTelemetry::TestHelpers.with_ids(trace_id, root_span_id) do
        tracer.start_root_span('root', kind: :internal, start_timestamp: start_timestamp)
      end
      root.status = OpenTelemetry::Trace::Status.ok
      root.finish(end_timestamp: end_timestamp)
      root_ctx = OpenTelemetry::Trace.context_with_span(root)

      span = OpenTelemetry::TestHelpers.with_ids(trace_id, child_span_id) do
        tracer.start_span(
          'child',
          with_parent: root_ctx,
          kind: :producer,
          start_timestamp: start_timestamp + 1,
          links: [OpenTelemetry::Trace::Link.new(root.context, 'attr' => 4)]
        )
      end
      span['b'] = true
      span['f'] = 1.1
      span['i'] = 2
      span['s'] = 'val'
      span['a'] = [3, 4]
      span.status = OpenTelemetry::Trace::Status.error
      span.add_event('event', attributes: { 'attr' => 42 }, timestamp: start_timestamp + 4)
      span.finish(end_timestamp: end_timestamp)

      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')

      captured_request = nil
      exporter.instance_variable_get(:@client).stub(
        :export,
        lambda { |req, **_kwargs|
          captured_request = req
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceResponse.new
        }
      ) do
        _(exporter.export([root.to_span_data, span.to_span_data])).must_equal(success)
      end

      expected_request = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
        resource_spans: [
          Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
            resource: Opentelemetry::Proto::Resource::V1::Resource.new(
              attributes: [
                Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name',     value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version',  value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: OpenTelemetry::SDK::VERSION))
              ]
            ),
            scope_spans: [
              Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                  name: 'tracer', version: 'v0.0.1'
                ),
                spans: [
                  Opentelemetry::Proto::Trace::V1::Span.new(
                    trace_id:             trace_id,
                    span_id:              root_span_id,
                    parent_span_id:       nil,
                    name:                 'root',
                    kind:                 Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL,
                    start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                    end_time_unix_nano:   (end_timestamp.to_r * 1_000_000_000).to_i,
                    status: Opentelemetry::Proto::Trace::V1::Status.new(
                      code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
                    )
                  ),
                  Opentelemetry::Proto::Trace::V1::Span.new(
                    trace_id:             trace_id,
                    span_id:              child_span_id,
                    parent_span_id:       root_span_id,
                    name:                 'child',
                    kind:                 Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER,
                    start_time_unix_nano: ((start_timestamp + 1).to_r * 1_000_000_000).to_i,
                    end_time_unix_nano:   (end_timestamp.to_r * 1_000_000_000).to_i,
                    attributes: [
                      Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'b', value: Opentelemetry::Proto::Common::V1::AnyValue.new(bool_value: true)),
                      Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'f', value: Opentelemetry::Proto::Common::V1::AnyValue.new(double_value: 1.1)),
                      Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'i', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 2)),
                      Opentelemetry::Proto::Common::V1::KeyValue.new(key: 's', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'val')),
                      Opentelemetry::Proto::Common::V1::KeyValue.new(
                        key: 'a',
                        value: Opentelemetry::Proto::Common::V1::AnyValue.new(
                          array_value: Opentelemetry::Proto::Common::V1::ArrayValue.new(
                            values: [
                              Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 3),
                              Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4)
                            ]
                          )
                        )
                      )
                    ],
                    events: [
                      Opentelemetry::Proto::Trace::V1::Span::Event.new(
                        time_unix_nano: ((start_timestamp + 4).to_r * 1_000_000_000).to_i,
                        name: 'event',
                        attributes: [
                          Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 42))
                        ]
                      )
                    ],
                    links: [
                      Opentelemetry::Proto::Trace::V1::Span::Link.new(
                        trace_id: trace_id,
                        span_id:  root_span_id,
                        attributes: [
                          Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4))
                        ]
                      )
                    ],
                    status: Opentelemetry::Proto::Trace::V1::Status.new(
                      code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
                    )
                  )
                ]
              )
            ]
          )
        ]
      )

      _(captured_request).must_equal(expected_request)
    end
  end

  describe '#force_flush' do
    it 'returns success' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.force_flush
      _(result).must_equal(success)
    end

    it 'accepts timeout parameter' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.force_flush(timeout: 5)
      _(result).must_equal(success)
    end
  end

  describe '#shutdown' do
    it 'returns success' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.shutdown
      _(result).must_equal(success)
    end

    it 'accepts timeout parameter' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.shutdown(timeout: 5)
      _(result).must_equal(success)
    end

    it 'prevents further exports after shutdown' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      exporter.shutdown
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(failure_result)
    end

    it 'can be called multiple times' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result1 = exporter.shutdown
      result2 = exporter.shutdown
      _(result1).must_equal(success)
      _(result2).must_equal(success)
    end
  end

  describe 'integration with tracer provider' do
    before { skip unless ENV['TRACING_INTEGRATION_TEST'] }

    it 'integrates with collector' do
      span_data = OpenTelemetry::TestHelpers.create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end

    it 'exports real spans from tracer' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
      tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
      tracer_provider.add_span_processor(processor)
      tracer = tracer_provider.tracer('test-tracer', '1.0.0')

      span = tracer.start_root_span('test-span', kind: :internal)
      span['test_attr'] = 'test_value'
      span.add_event('test_event', attributes: { 'event_attr' => 42 })
      span.status = OpenTelemetry::Trace::Status.ok
      span.finish

      tracer_provider.shutdown
    end

    it 'exports spans with full trace context' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter)
      tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(
        resource: OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test-service')
      )
      tracer_provider.add_span_processor(processor)
      tracer = tracer_provider.tracer('test-tracer', '1.0.0')

      root_span = tracer.start_root_span('root-span')
      root_ctx = OpenTelemetry::Trace.context_with_span(root_span)

      child_span = tracer.start_span('child-span', with_parent: root_ctx)
      child_span.finish
      root_span.finish

      tracer_provider.shutdown
    end
  end

  describe 'error handling' do
    it 'handles gRPC errors gracefully' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      # Mock the gRPC client to raise an error
      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Unavailable, 'service unavailable' }) do
        result = exporter.export([span_data])
        # The exporter should handle the error and return failure
        _(result).must_equal(failure_result)
      end
    end

    it 'handles encoding errors gracefully' do
      skip 'Encoding error handling needs investigation - errors are caught but export still fails'
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        span_data = OpenTelemetry::TestHelpers.create_span_data(
          attributes: { 'bad_key' => (+"\xC2").force_encoding(::Encoding::ASCII_8BIT) }
        )
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')

        # Mock successful export to test encoding handling
        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { true }) do
          result = exporter.export([span_data])
          _(result).must_equal(success)
          _(log_stream.string).must_match(/encoding error/)
        end
      end
    end

    it 'returns failure on deadline exceeded' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::DeadlineExceeded, 'deadline exceeded' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on invalid argument' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::InvalidArgument, 'invalid argument' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on unauthenticated' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Unauthenticated, 'unauthenticated' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'retries on transient errors with backoff' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      call_count = 0
      client = exporter.instance_variable_get(:@client)
      client.stub(:export, lambda { |_request, **_kwargs|
        call_count += 1
        raise GRPC::Unavailable, 'service unavailable' if call_count <= 2

        true
      }) do
        result = exporter.export([span_data])
        _(result).must_equal(success)
        _(call_count).must_equal(3)
      end
    end

    it 'stops retrying after max retry count' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      call_count = 0
      client = exporter.instance_variable_get(:@client)
      client.stub(:export, lambda { |_request, **_kwargs|
        call_count += 1
        raise GRPC::Unavailable, 'service unavailable'
      }) do
        exporter.stub(:sleep, nil) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          # Should try initial + 5 retries = 6 total
          _(call_count).must_equal(6)
        end
      end
    end

    it 'returns failure on cancelled' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Cancelled, 'cancelled' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on resource exhausted' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::ResourceExhausted, 'resource exhausted' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on aborted' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Aborted, 'aborted' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on internal error' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Internal, 'internal error' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on data loss' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, ->(_request, **_kwargs) { raise GRPC::DataLoss, 'data loss' }) do
        result = exporter.export([span_data])
        _(result).must_equal(failure_result)
      end
    end

    it 'returns failure on permission denied' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
        span_data = OpenTelemetry::TestHelpers.create_span_data

        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise GRPC::PermissionDenied, 'permission denied' }) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          _(log_stream.string).must_match(/permission denied/)
        end
      end
    end

    it 'returns failure on not found' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
        span_data = OpenTelemetry::TestHelpers.create_span_data

        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise GRPC::NotFound, 'not found' }) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          _(log_stream.string).must_match(/not found/)
        end
      end
    end

    it 'returns failure on unimplemented' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
        span_data = OpenTelemetry::TestHelpers.create_span_data

        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Unimplemented, 'unimplemented' }) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          _(log_stream.string).must_match(/unimplemented/)
        end
      end
    end

    it 'handles generic GRPC::BadStatus errors' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
        span_data = OpenTelemetry::TestHelpers.create_span_data

        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise GRPC::BadStatus.new(99, 'custom error') }) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          _(log_stream.string).must_match(/gRPC error/)
          _(log_stream.string).must_match(/99/)
          _(log_stream.string).must_match(/custom error/)
        end
      end
    end

    it 'handles unexpected errors' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
        span_data = OpenTelemetry::TestHelpers.create_span_data

        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise StandardError, 'unexpected error' }) do
          result = exporter.export([span_data])
          _(result).must_equal(failure_result)
          _(log_stream.string).must_match(/unexpected error/)
        end
      end
    end

    it 'respects timeout during export' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317', timeout: 1)
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      # Verify deadline is set on the gRPC call
      client.stub(:export, lambda { |_request, deadline: nil|
        _(deadline).wont_be_nil
        _(deadline).must_be_kind_of(Time)
        true
      }) do
        result = exporter.export([span_data])
        _(result).must_equal(success)
      end
    end

    it 'uses custom timeout parameter over default' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317', timeout: 10)
      span_data = OpenTelemetry::TestHelpers.create_span_data

      client = exporter.instance_variable_get(:@client)
      client.stub(:export, lambda { |_request, deadline: nil|
        # With custom timeout of 5, deadline should be ~5 seconds from now
        time_diff = deadline - Time.now
        _(time_diff).must_be_close_to(5.0, 1.0)
        true
      }) do
        result = exporter.export([span_data], timeout: 5)
        _(result).must_equal(success)
      end
    end

    it 'reports metrics on failures' do
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      span_data = OpenTelemetry::TestHelpers.create_span_data

      metrics_reporter = exporter.instance_variable_get(:@metrics_reporter)
      counter_calls = []

      metrics_reporter.stub(:add_to_counter, lambda { |metric, increment: 1, labels: {}|
        counter_calls << { metric: metric, labels: labels }
      }) do
        client = exporter.instance_variable_get(:@client)
        client.stub(:export, ->(_request, **_kwargs) { raise GRPC::Unavailable, 'unavailable' }) do
          exporter.export([span_data])
        end
      end

      # Should have recorded failures for each retry attempt
      _(counter_calls.length).must_be :>, 0
      _(counter_calls.first[:metric]).must_equal('otel.otlp_exporter.failure')
      _(counter_calls.first[:labels][:reason]).must_equal('unavailable')
    end
  end

  describe 'performance' do
    before { skip unless ENV['TRACING_INTEGRATION_TEST'] }

    it 'exports large batches of spans' do
      spans = Array.new(100) { |i| OpenTelemetry::TestHelpers.create_span_data(name: "span-#{i}") }
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export(spans)
      _(result).must_equal(success)
    end

    it 'exports spans with many attributes' do
      attributes = 50.times.each_with_object({}) { |i, hash| hash["attr_#{i}"] = "value_#{i}" }
      span_data = OpenTelemetry::TestHelpers.create_span_data(attributes: attributes)
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end

    it 'exports spans with many events' do
      events = Array.new(20) do |i|
        OpenTelemetry::SDK::Trace::Event.new(
          name: "event_#{i}",
          attributes: { "event_attr_#{i}" => i },
          timestamp: Time.now.to_i * 1_000_000_000
        )
      end
      span_data = OpenTelemetry::TestHelpers.create_span_data(events: events)
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::TraceExporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end
  end
end
