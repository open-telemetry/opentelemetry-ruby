# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'google/protobuf/wrappers_pb'
require 'google/protobuf/well_known_types'

describe OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient do
  describe 'ssl_verify_mode:' do
    it 'can be set to VERIFY_NONE by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true') do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'EXAMPLE')
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
    end

    it 'can be set to VERIFY_PEER by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'EXAMPLE')
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end

    it 'VERIFY_PEER will override VERIFY_NONE' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'EXAMPLE')
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end
  end

  describe '#export_bytes' do
    let(:config) do
      OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(
        endpoint: 'http://localhost:4318/v1/traces'
      )
    end

    let(:client) do
      OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(
        config,
        'TRACES',
        'v1/traces'
      )
    end

    let(:bytes) { 'test payload' }

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      result = client.export_bytes(bytes)
      _(result).must_equal(success)
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces')
        .to_timeout.then.to_return(status: 200)

      result = client.export_bytes(bytes)

      _(result.success).must_equal(true)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      result = client.export_bytes(bytes, timeout: 0)
      _(result.success).must_equal(false)
    end

    it 'returns FAILURE on unexpected exceptions' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise('something unexpected')
      result = client.export_bytes(bytes)

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Exporter#send_bytes - something unexpected/
      )

      _(result.success).must_equal(false)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'returns TIMEOUT on timeout after retrying' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_timeout.then.to_raise('this should not be reached')

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      client.stub(:backoff?, backoff_stubbed_call) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    ensure
      @retry_count = 0
    end

    it 'returns FAILURE when encryption to receiver endpoint fails' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(OpenSSL::SSL::SSLError.new('enigma wedged'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'exports a span_data' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 200)
      result = client.export_bytes(bytes)
      _(result.success).must_equal(true)
    end

    it 'logs rpc.Status on bad request' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 400, body: 'status')

      result = client.export_bytes(bytes)

      _(result.success).must_equal(false)
    end

    it 'logs a specific message when there is a 404' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 404, body: "Not Found\n")
      result = client.export_bytes(bytes)

      _(log_stream.string).must_match(
        %r{ERROR -- : OpenTelemetry error: OTLP exporter received http\.code=404 for uri='http://localhost:4318/v1/traces'}
      )

      _(result.success).must_equal(false)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles 503' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 503, body: 'Service Unavailable')

      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles 429' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_return(status: 429, body: 'Too Many Requests')

      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles Zlib gzip compression errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(Zlib::DataError.new('data error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles OpenTimeout errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(Net::OpenTimeout.new('timeout error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles SocketError errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(SocketError.new('socket error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles SystemCallError errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(SystemCallError.new('system call error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles EOFError errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(EOFError.new('end of file error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end

    it 'handles StandardError errors' do
      stub_request(:post, 'http://localhost:4318/v1/traces').to_raise(StandardError.new('standard error'))
      client.stub(:backoff?, ->(**_) { false }) do
        result = client.export_bytes(bytes)
        _(result.success).must_equal(false)
      end
    end
  end
end
