# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new
      _(exp).wont_be_nil
      _(exp.instance_variable_get(:@headers)).must_be_empty
      _(exp.instance_variable_get(:@timeout)).must_equal 10.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/traces'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_be_nil
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
      _(http.port).must_equal 4318
    end

    it 'refuses invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'not a url')
      end
    end

    it 'uses endpoints path if provided' do
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'https://localhost/custom/path')
      _(exp.instance_variable_get(:@path)).must_equal '/custom/path'
    end

    it 'only allows gzip compression or none' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::Exporter.new(compression: 'flate')
      end
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: nil)
      _(exp.instance_variable_get(:@compression)).must_be_nil

      %w[gzip none].each do |compression|
        exp = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: compression)
        _(exp.instance_variable_get(:@compression)).must_equal(compression)
      end

      [
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'none' },
        { envar: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', value: 'none' }
      ].each do |example|
        with_env(example[:envar] => example[:value]) do
          exp = OpenTelemetry::Exporter::OTLP::Exporter.new
          _(exp.instance_variable_get(:@compression)).must_equal(example[:value])
        end
      end
    end

    it 'sets parameters from the environment' do
      exp = with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                     'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                     'OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d',
                     'OTEL_EXPORTER_OTLP_COMPRESSION' => 'gzip',
                     'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                     'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::Exporter.new
      end
      _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd')
      _(exp.instance_variable_get(:@timeout)).must_equal 11.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/traces'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/foo/bar'
      _(http.use_ssl?).must_equal true
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.port).must_equal 1234
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                     'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                     'OTEL_EXPORTER_OTLP_HEADERS' => 'a:b,c:d',
                     'OTEL_EXPORTER_OTLP_COMPRESSION' => 'flate',
                     'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true',
                     'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4321',
                                                    certificate_file: '/baz',
                                                    headers: { 'x' => 'y' },
                                                    compression: 'gzip',
                                                    ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                                    timeout: 12)
      end
      _(exp.instance_variable_get(:@headers)).must_equal('x' => 'y')
      _(exp.instance_variable_get(:@timeout)).must_equal 12.0
      _(exp.instance_variable_get(:@path)).must_equal ''
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/baz'
      _(http.use_ssl?).must_equal false
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4321
    end

    it 'restricts explicit headers to a String or Hash' do
      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(headers: { 'token' => 'über' })
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')

      exp = OpenTelemetry::Exporter::OTLP::Exporter.new(headers: 'token=%C3%BCber')
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')

      error = _() {
        exp = OpenTelemetry::Exporter::OTLP::Exporter.new(headers: Object.new)
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')
      }.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    describe 'Headers Environment Variable' do
      it 'allows any number of the equal sign (=) characters in the value' do
        exp = with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f')

        exp = with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f')
      end

      it 'trims any leading or trailing whitespaces in keys and values' do
        exp = with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f')

        exp = with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f')
      end

      it 'decodes values as URL encoded UTF-8 strings' do
        exp = with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')

        exp = with_env('OTEL_EXPORTER_OTLP_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token')

        exp = with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')

        exp = with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token')
      end

      it 'prefers TRACES specific variable' do
        exp = with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f', 'OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::Exporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')
      end

      it 'fails fast when header values are missing' do
        error = _() {
          with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _() {
          with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header or values are not found' do
        error = _() {
          with_env('OTEL_EXPORTER_OTLP_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _() {
          with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header values contain invalid escape characters' do
        error = _() {
          with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _() {
          with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when headers are invalid' do
        error = _() {
          with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _() {
          with_env('OTEL_EXPORTER_OTLP_TRACES_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::Exporter.new
          end
        }.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end
    end
  end

  describe 'ssl_verify_mode:' do
    it 'can be set to VERIFY_NONE by an envvar' do
      exp = with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true') do
        OpenTelemetry::Exporter::OTLP::Exporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
    end

    it 'can be set to VERIFY_PEER by an envvar' do
      exp = with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::Exporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end

    it 'VERIFY_PEER will override VERIFY_NONE' do
      exp = with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                     'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
                       OpenTelemetry::Exporter::OTLP::Exporter.new
                     end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::OTLP::Exporter.new }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
    end

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      span_data = create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'http://localhost:4318', compression: 'gzip')
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_timeout.then.to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data], timeout: 0)
      _(result).must_equal(FAILURE)
    end

    it 'returns FAILURE on unexpected exceptions' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise('something unexpected')
      span_data = create_span_data
      result = exporter.export([span_data], timeout: 1)

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Exporter#send_bytes - something unexpected/
      )

      _(result).must_equal(FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles encoding failures' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = create_span_data

      Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.stub(:encode, ->(_) { raise 'a little hell' }) do
        _(exporter.export([span_data], timeout: 1)).must_equal(FAILURE)
      end

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Exporter#encode - a little hell/
      )
    ensure
      OpenTelemetry.logger = logger
    end

    it 'returns TIMEOUT on timeout after retrying' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_timeout.then.to_raise('this should not be reached')
      span_data = create_span_data

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      exporter.stub(:backoff?, backoff_stubbed_call) do
        _(exporter.export([span_data], timeout: 0.1)).must_equal(FAILURE)
      end
    ensure
      @retry_count = 0
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'returns FAILURE when encryption to receiver endpoint fails' do
      exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(endpoint: 'https://localhost:4318/v1/traces')
      stub_request(:post, 'https://localhost:4318/v1/traces').to_raise(OpenSSL::SSL::SSLError.new('enigma wedged'))
      span_data = create_span_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([span_data])).must_equal(FAILURE)
      end
    end

    it 'exports a span_data' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'handles encoding errors with poise and grace' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      span_data = create_span_data(total_recorded_attributes: 1, attributes: { 'a' => "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT) })

      result = exporter.export([span_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: encoding error for key a and value �/
      )

      _(result).must_equal(SUCCESS)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles Zlib gzip compression errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(Zlib::DataError.new('data error'))
      span_data = create_span_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([span_data])).must_equal(FAILURE)
      end
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
      exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(compression: 'gzip')
      stub_post = stub_request(:post, 'http://localhost:4318/v1/traces').to_return do |request|
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(Zlib.gunzip(request.body))
        { status: 200 }
      end

      span_data = create_span_data
      result = exporter.export([span_data])

      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      etsr = nil
      stub_post = stub_request(:post, 'http://localhost:4318/v1/traces').to_return do |request|
        proto = Zlib.gunzip(request.body)
        etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(proto)
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
      root = with_ids(trace_id, root_span_id) { tracer.start_root_span('root', kind: :internal, start_timestamp: start_timestamp) }
      root.status = OpenTelemetry::Trace::Status.ok
      root.finish(end_timestamp: end_timestamp)
      root_ctx = OpenTelemetry::Trace.context_with_span(root)
      span = with_ids(trace_id, child_span_id) { tracer.start_span('child', with_parent: root_ctx, kind: :producer, start_timestamp: start_timestamp + 1, links: [OpenTelemetry::Trace::Link.new(root.context, 'attr' => 4)]) }
      span['b'] = true
      span['f'] = 1.1
      span['i'] = 2
      span['s'] = 'val'
      span['a'] = [3, 4]
      span.status = OpenTelemetry::Trace::Status.error
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
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL,
                      start_time_unix_nano: (start_timestamp.to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
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
                          ]
                        )
                      ],
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
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
                      kind: Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER,
                      start_time_unix_nano: ((start_timestamp + 3).to_r * 1_000_000_000).to_i,
                      end_time_unix_nano: (end_timestamp.to_r * 1_000_000_000).to_i,
                      status: Opentelemetry::Proto::Trace::V1::Status.new(
                        code: Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
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
        req.body == Zlib.gzip(encoded_etsr)
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
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: exportable_timestamp,
                       end_timestamp: exportable_timestamp, attributes: nil, links: nil, events: nil, resource: nil,
                       instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('', 'v0.0.1'),
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
  end
end
