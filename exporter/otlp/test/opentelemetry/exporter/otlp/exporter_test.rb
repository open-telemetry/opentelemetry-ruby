# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
  TIMEOUT = OpenTelemetry::SDK::Trace::Export::TIMEOUT

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new
      _(exp).wont_be_nil
      _(exp.instance_variable_get(:@headers)).must_be_nil
      _(exp.instance_variable_get(:@timeout)).must_equal 10.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/trace'
      _(exp.instance_variable_get(:@compression)).must_be_nil
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_be_nil
      _(http.use_ssl?).must_equal true
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4317
    end

    it 'refuses invalid headers' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::Exporter.new(headers: 'a:b,c')
      end
    end

    it 'refuses invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'not a url')
      end
    end

    it 'only allows gzip compression or none' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::Exporter.new(compression: 'flate')
      end
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: 'gzip')
      _(exp).wont_be_nil
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: nil)
      _(exp).wont_be_nil
    end

    it 'sets parameters from the environment' do
      exp = with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://localhost:1234',
                     'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                     'OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d',
                     'OTEL_EXPORTER_OTLP_COMPRESSION' => 'gzip',
                     'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::Exporter.new
      end
      _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd')
      _(exp.instance_variable_get(:@timeout)).must_equal 11.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/trace'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/foo/bar'
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 1234
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                     'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                     'OTEL_EXPORTER_OTLP_HEADERS' => 'a:b,c:d',
                     'OTEL_EXPORTER_OTLP_COMPRESSION' => 'flate',
                     'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4321',
                                                    certificate_file: '/baz',
                                                    headers: { 'x' => 'y' },
                                                    compression: 'gzip',
                                                    timeout: 12)
      end
      _(exp.instance_variable_get(:@headers)).must_equal('x' => 'y')
      _(exp.instance_variable_get(:@timeout)).must_equal 12.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/trace'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/baz'
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4321
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::OTLP::Exporter.new }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
    end

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      span_data = create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4317', compression: 'gzip')
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'retries on timeout' do
      stub_request(:post, 'https://localhost:4317/v1/trace').to_timeout.then.to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'https://localhost:4317/v1/trace').to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data], timeout: 0)
      _(result).must_equal(TIMEOUT)
    end

    it 'returns TIMEOUT on timeout after retrying' do
      stub_request(:post, 'https://localhost:4317/v1/trace').to_timeout.then.to_raise('this should not be reached')
      span_data = create_span_data

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      exporter.stub(:backoff?, backoff_stubbed_call) do
        _(exporter.export([span_data], timeout: 0.1)).must_equal(TIMEOUT)
      end
    ensure
      @retry_count = 0
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'exports a span_data' do
      stub_request(:post, 'https://localhost:4317/v1/trace').to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, 'https://localhost:4317/v1/trace').to_return(status: 200)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    it 'compresses with gzip if enabled' do
      exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: 'gzip')
      etsr = nil
      stub_post = stub_request(:post, 'https://localhost:4317/v1/trace').to_return do |request|
        etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(Zlib.gunzip(request.body))
        { status: 200 }
      end

      span_data = create_span_data
      result = exporter.export([span_data])

      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      etsr = nil
      stub_post = stub_request(:post, 'https://localhost:4317/v1/trace').to_return do |request|
        etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(request.body)
        { status: 200 }
      end

      span_data1 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      span_data2 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([span_data1, span_data2])

      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
      _(etsr.resource_spans.length).must_equal(2)
    end

    it 'translates all the things' do
      stub_request(:post, 'https://localhost:4317/v1/trace').to_return(status: 200)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter)
      tracer = OpenTelemetry.tracer_provider.tracer('tracer', 'v0.0.1')
      other_tracer = OpenTelemetry.tracer_provider.tracer('other_tracer')

      trace_id = OpenTelemetry::Trace.generate_trace_id
      root_span_id = OpenTelemetry::Trace.generate_span_id
      child_span_id = OpenTelemetry::Trace.generate_span_id
      client_span_id = OpenTelemetry::Trace.generate_span_id
      server_span_id = OpenTelemetry::Trace.generate_span_id
      consumer_span_id = OpenTelemetry::Trace.generate_span_id
      start_timestamp = Time.now
      end_timestamp = start_timestamp + 6

      OpenTelemetry.tracer_provider.add_span_processor(processor)
      root = with_ids(trace_id, root_span_id) { tracer.start_root_span('root', kind: :internal, start_timestamp: start_timestamp).finish(end_timestamp: end_timestamp) }
      root_ctx = OpenTelemetry::Trace.context_with_span(root)
      span = with_ids(trace_id, child_span_id) { tracer.start_span('child', with_parent: root_ctx, kind: :producer, start_timestamp: start_timestamp + 1, links: [OpenTelemetry::Trace::Link.new(root.context, 'attr' => 4)]) }
      span['b'] = true
      span['f'] = 1.1
      span['i'] = 2
      span['s'] = 'val'
      span['a'] = [3, 4]
      span.status = OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::ERROR)
      child_ctx = OpenTelemetry::Trace.context_with_span(span)
      client = with_ids(trace_id, client_span_id) { tracer.start_span('client', with_parent: child_ctx, kind: :client, start_timestamp: start_timestamp + 2).finish(end_timestamp: end_timestamp) }
      client_ctx = OpenTelemetry::Trace.context_with_span(client)
      with_ids(trace_id, server_span_id) { other_tracer.start_span('server', with_parent: client_ctx, kind: :server, start_timestamp: start_timestamp + 3).finish(end_timestamp: end_timestamp) }
      span.add_event('event', attributes: { 'attr' => 42 }, timestamp: start_timestamp + 4)
      with_ids(trace_id, consumer_span_id) { tracer.start_span('consumer', with_parent: child_ctx, kind: :consumer, start_timestamp: start_timestamp + 5).finish(end_timestamp: end_timestamp) }
      span.finish(end_timestamp: end_timestamp)
      OpenTelemetry.tracer_provider.shutdown

      encoded_etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
          resource_spans: [
            Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
              resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                attributes: [
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: OpenTelemetry::SDK::VERSION))
                ]
              ),
              instrumentation_library_spans: [
                Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                  instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                    name: 'tracer',
                    version: 'v0.0.1'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: root_span_id,
                      parent_span_id: nil,
                      name: 'root',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::INTERNAL,
                      start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::Ok
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: client_span_id,
                      parent_span_id: child_span_id,
                      name: 'client',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::CLIENT,
                      start_time_unix_nano: ((start_timestamp + 2).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::Ok
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: consumer_span_id,
                      parent_span_id: child_span_id,
                      name: 'consumer',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::CONSUMER,
                      start_time_unix_nano: ((start_timestamp + 5).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::Ok
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: child_span_id,
                      parent_span_id: root_span_id,
                      name: 'child',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::PRODUCER,
                      start_time_unix_nano: ((start_timestamp + 1).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
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
                          span_id: root_span_id,
                          attributes: [
                            Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'attr', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 4))
                          ]
                        )
                      ],
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::UnknownError
                      )
                    )
                  ]
                ),
                Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                  instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                    name: 'other_tracer'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: server_span_id,
                      parent_span_id: client_span_id,
                      name: 'server',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SERVER,
                      start_time_unix_nano: ((start_timestamp + 3).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::Ok
                      )
                    )
                  ]
                )
              ]
            )
          ]
        )
      )

      assert_requested(:post, 'https://localhost:4317/v1/trace') do |req|
        req.body == encoded_etsr
      end
    end
  end

  def with_ids(trace_id, span_id)
    OpenTelemetry::Trace.stub(:generate_trace_id, trace_id) do
      OpenTelemetry::Trace.stub(:generate_span_id, span_id) do
        yield
      end
    end
  end

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                       end_timestamp: Time.now, attributes: nil, links: nil, events: nil, resource: nil,
                       instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('', 'v0.0.1'),
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
  end
end
