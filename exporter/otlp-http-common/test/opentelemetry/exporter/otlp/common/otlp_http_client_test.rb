# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'google/protobuf/wrappers_pb'
require 'google/protobuf/well_known_types'

describe OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient do
  describe 'initialize:' do
    DEFAULT_USER_AGENT = "OTel-OTLP-HTTP-TRACES-Exporter-Ruby/#{OpenTelemetry::Exporter::OTLP::HTTP::Common::VERSION}".freeze
    it 'sets parameters from the environment' do
      http = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                 'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                                                 'OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d',
                                                 'OTEL_EXPORTER_OTLP_COMPRESSION' => 'gzip',
                                                 'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                 'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      options = http.instance_variable_get(:@options)
      _(options.headers).must_equal([{ name: 'a', value: 'b' }, { name: 'c', value: 'd' }, { name: 'User-Agent', value: DEFAULT_USER_AGENT }])
      _(options.timeout).must_equal 11.0
      _(http.instance_variable_get(:@uri).path).must_equal '/v1/traces'
      _(options.compression).must_equal 'gzip'
      _(http.ca_file).must_equal '/foo/bar'
      _(http.use_ssl?).must_equal true
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.port).must_equal 1234
    end

    it 'prefers explicit parameters rather than the environment' do
      http = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                 'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                                                 'OTEL_EXPORTER_OTLP_HEADERS' => 'a:b,c:d',
                                                 'OTEL_EXPORTER_OTLP_COMPRESSION' => 'flate',
                                                 'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true',
                                                 'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(
          OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(endpoint: 'http://localhost:4321',
                                                                          certificate_file: '/baz',
                                                                          headers: { 'x' => 'y' },
                                                                          compression: 'gzip',
                                                                          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                                                          timeout: 12),
          'TRACES',
          'v1/traces'
        )
      end
      options = http.instance_variable_get(:@options)
      _(options.headers).must_equal([{ name: 'x', value: 'y' }, { name: 'User-Agent', value: DEFAULT_USER_AGENT }])
      _(options.timeout).must_equal 12.0
      _(http.instance_variable_get(:@uri).path).must_equal '' # to do check if it should be '/v1/traces'
      _(options.compression).must_equal 'gzip'
      _(http.ca_file).must_equal '/baz'
      _(http.use_ssl?).must_equal false
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4321
    end
  end

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

  describe 'compression:' do
    it 'only allows gzip compression or none' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(compression: 'flate'), 'TRACES')
      end
      exp = OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(compression: nil), 'TRACES')
      _(exp.instance_variable_get(:@compression)).must_be_nil

      %w[gzip none].each do |compression|
        exp = OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(compression: compression), 'TRACES', 'v1/traces')
        _(exp.instance_variable_get(:@options).compression).must_equal(compression)
      end

      [
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'none' },
        { envar: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', value: 'none' }
      ].each do |example|
        OpenTelemetry::TestHelpers.with_env(example[:envar] => example[:value]) do
          exp = OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
          _(exp.instance_variable_get(:@options).compression).must_equal(example[:value])
        end
      end
    end
  end

  describe 'uri:' do
    it 'uses endpoints path if provided' do
      exp = OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(endpoint: 'https://localhost/custom/path'), 'TRACES', 'v1/traces')
      _(exp.instance_variable_get(:@uri).path).must_equal '/custom/path'
    end

    it 'refuses invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(endpoint: 'not a url'), 'TRACES', 'v1/traces')
      end
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT has a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/v1/traces'
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT does not have a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/v1/traces'
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT does have a path without a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        # simulate OTLP endpoints built on top of an existing API
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/api/v2/otlp'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/api/v2/otlp/v1/traces'
    end

    it 'does not join endpoint with v1/traces if endpoint is set and is equal to OTEL_EXPORTER_OTLP_ENDPOINT' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/custom/path'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(endpoint: 'https://localhost:1234/custom/path'), 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/custom/path'
    end

    it 'does not append v1/traces if OTEL_EXPORTER_OTLP_ENDPOINT and OTEL_EXPORTER_OTLP_TRACES_ENDPOINT both equal' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/custom/path',
        'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'https://localhost:1234/custom/path'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/custom/path'
    end

    it 'uses OTEL_EXPORTER_OTLP_TRACES_ENDPOINT over OTEL_EXPORTER_OTLP_ENDPOINT' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/non/specific/custom/path',
        'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'https://localhost:1234/specific/custom/path'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(nil, 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/specific/custom/path'
    end

    it 'uses endpoint over OTEL_EXPORTER_OTLP_TRACES_ENDPOINT and OTEL_EXPORTER_OTLP_ENDPOINT' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/non/specific/custom/path',
        'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' => 'https://localhost:1234/specific/custom/path'
      ) do
        OpenTelemetry::Exporter::OTLP::HTTP::OTLPHTTPClient.new(OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new(endpoint: 'https://localhost:1234/endpoint/custom/path'), 'TRACES', 'v1/traces')
      end
      _(exp.instance_variable_get(:@uri).path).must_equal '/endpoint/custom/path'
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
