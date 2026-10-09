# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'google/protobuf/wrappers_pb'
require 'google/protobuf/well_known_types'

describe OpenTelemetry::Exporter::OTLP::HTTP::TraceExporter do
  let(:success) { OpenTelemetry::SDK::Trace::Export::SUCCESS }
  let(:export_failure) { OpenTelemetry::SDK::Trace::Export::FAILURE }

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::OTLP::HTTP::TraceExporter.new
      _(exp).wont_be_nil
      http = exp.instance_variable_get(:@http)
      options = http.instance_variable_get(:@options)
      _(options.timeout).must_equal 10.0
      _(http.uri.path).must_equal '/v1/traces'
      _(options.compression).must_equal 'gzip'
      _(http.ca_file).must_be_nil
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
      _(http.port).must_equal 4318
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::OTLP::HTTP::TraceExporter.new }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
    end

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      span_data = OpenTelemetry::TestHelpers.create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::HTTP::TraceExporter.new(endpoint: 'http://localhost:4318/v1/traces', compression: 'gzip')
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_timeout.then.to_return(status: 200)
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data], timeout: 0)
      _(result).must_equal(export_failure)
    end

    it 'returns FAILURE on unexpected exceptions' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise('something unexpected')
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data], timeout: 1)

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Exporter#send_bytes - something unexpected/
      )

      _(result).must_equal(export_failure)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles encoding failures' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = OpenTelemetry::TestHelpers.create_span_data

      Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.stub(:encode, ->(_) { raise 'a little hell' }) do
        _(exporter.export([span_data], timeout: 1)).must_equal(export_failure)
      end

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Common#as_encoded_etsr - a little hell/
      )
    ensure
      OpenTelemetry.logger = logger
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(export_failure)
    end

    it 'exports a span_data' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(success)
    end

    it 'handles encoding errors with poise and grace' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = OpenTelemetry::TestHelpers.create_span_data(total_recorded_attributes: 1, attributes: { 'a' => (+"\xC2").force_encoding(::Encoding::ASCII_8BIT) })

      result = exporter.export([span_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: encoding error for key a and value �/
      )

      _(result).must_equal(success)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs rpc.Status on bad request' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      details = [::Google::Protobuf::Any.pack(::Google::Protobuf::StringValue.new(value: 'you are a bad request'))]
      status = ::Google::Rpc::Status.encode(::Google::Rpc::Status.new(code: 1, message: 'bad request', details: details))
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 400, body: status)
      span_data = OpenTelemetry::TestHelpers.create_span_data

      result = exporter.export([span_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: OTLP exporter received rpc.Status{message=bad request, details=\[.*you are a bad request.*\]}/
      )

      _(result).must_equal(export_failure)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs a specific message when there is a 404' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 404, body: "Not Found\n")
      span_data = OpenTelemetry::TestHelpers.create_span_data

      result = exporter.export([span_data])

      _(log_stream.string).must_match(
        %r{ERROR -- : OpenTelemetry error: OTLP exporter received http\.code=404 for uri='http://localhost:4318/v1/traces'}
      )

      _(result).must_equal(export_failure)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    it 'compresses with gzip if enabled' do
      exporter = OpenTelemetry::Exporter::OTLP::HTTP::TraceExporter.new(compression: 'gzip')
      stub_post = stub_request(:post, 'http://localhost:4318/v1/traces').to_return do |request|
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(Zlib.gunzip(request.body))
        { status: 200 }
      end

      span_data = OpenTelemetry::TestHelpers.create_span_data
      result = exporter.export([span_data])

      _(result).must_equal(success)
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      etsr = nil
      stub_post = stub_request(:post, 'http://localhost:4318/v1/traces').to_return do |request|
        proto = Zlib.gunzip(request.body)
        etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(proto)
        { status: 200 }
      end

      span_data1 = OpenTelemetry::TestHelpers.create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      span_data2 = OpenTelemetry::TestHelpers.create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([span_data1, span_data2])

      _(result).must_equal(success)
      assert_requested(stub_post)
      _(etsr.resource_spans.length).must_equal(2)
    end

    it 'translates all the things' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
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
      root = OpenTelemetry::TestHelpers.with_ids(trace_id, root_span_id) { tracer.start_root_span('root', kind: :internal, start_timestamp: start_timestamp) }
      root.status = OpenTelemetry::Trace::Status.ok
      root.finish(end_timestamp: end_timestamp)
      root_ctx = OpenTelemetry::Trace.context_with_span(root)
      span = OpenTelemetry::TestHelpers.with_ids(trace_id, child_span_id) { tracer.start_span('child', with_parent: root_ctx, kind: :producer, start_timestamp: start_timestamp + 1, links: [OpenTelemetry::Trace::Link.new(root.context, 'attr' => 4)]) }
      span['b'] = true
      span['f'] = 1.1
      span['i'] = 2
      span['s'] = 'val'
      span['a'] = [3, 4]
      span.status = OpenTelemetry::Trace::Status.error
      child_ctx = OpenTelemetry::Trace.context_with_span(span)
      client = OpenTelemetry::TestHelpers.with_ids(trace_id, client_span_id) { tracer.start_span('client', with_parent: child_ctx, kind: :client, start_timestamp: start_timestamp + 2).finish(end_timestamp: end_timestamp) }
      client_ctx = OpenTelemetry::Trace.context_with_span(client)
      OpenTelemetry::TestHelpers.with_ids(trace_id, server_span_id) { other_tracer.start_span('server', with_parent: client_ctx, kind: :server, start_timestamp: start_timestamp + 3).finish(end_timestamp: end_timestamp) }
      span.add_event('event', attributes: { 'attr' => 42 }, timestamp: start_timestamp + 4)
      OpenTelemetry::TestHelpers.with_ids(trace_id, consumer_span_id) { tracer.start_span('consumer', with_parent: child_ctx, kind: :consumer, start_timestamp: start_timestamp + 5).finish(end_timestamp: end_timestamp) }
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
              scope_spans: [
                Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'tracer',
                    version: 'v0.0.1'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: root_span_id,
                      parent_span_id: nil,
                      name: 'root',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL,
                      start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: client_span_id,
                      parent_span_id: child_span_id,
                      name: 'client',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT,
                      start_time_unix_nano: ((start_timestamp + 2).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: consumer_span_id,
                      parent_span_id: child_span_id,
                      name: 'consumer',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER,
                      start_time_unix_nano: ((start_timestamp + 5).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    ),
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: child_span_id,
                      parent_span_id: root_span_id,
                      name: 'child',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER,
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
                          ],
                          flags: (
                            Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                            1
                          )
                        )
                      ],
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    )
                  ]
                ),
                Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'other_tracer'
                  ),
                  spans: [
                    Opentelemetry::Proto::Trace::V1::Span.new(
                      trace_id: trace_id,
                      span_id: server_span_id,
                      parent_span_id: client_span_id,
                      name: 'server',
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER,
                      start_time_unix_nano: ((start_timestamp + 3).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
                      ),
                      flags: (
                        Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK |
                        1
                      )
                    )
                  ]
                )
              ]
            )
          ]
        )
      )

      assert_requested(:post, 'http://localhost:4318/v1/traces') do |req|
        Zlib.gunzip(req.body) == encoded_etsr
      end
    end
  end
end
