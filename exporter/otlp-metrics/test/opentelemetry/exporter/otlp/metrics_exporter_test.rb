# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'google/protobuf/wrappers_pb'
require 'google/protobuf/well_known_types'

describe OpenTelemetry::Exporter::OTLP::MetricsExporter do
  METRICS_SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS
  METRICS_FAILURE = OpenTelemetry::SDK::Metrics::Export::FAILURE
  METRICS_VERSION = OpenTelemetry::Exporter::OTLP::VERSION
  METRICS_DEFAULT_USER_AGENT = OpenTelemetry::Exporter::OTLP::Util::DEFAULT_USER_AGENT

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      _(exp).wont_be_nil
      _(exp.instance_variable_get(:@headers)).must_equal('User-Agent' => METRICS_DEFAULT_USER_AGENT)
      _(exp.instance_variable_get(:@timeout)).must_equal 10.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/metrics'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_be_nil
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
      _(http.port).must_equal 4318
    end

    it 'provides a useful, spec-compliant default user agent header' do
      _(METRICS_DEFAULT_USER_AGENT).must_match("OTel-OTLP-MetricsExporter-Ruby/#{METRICS_VERSION}")
      _(METRICS_DEFAULT_USER_AGENT).must_match("Ruby/#{RUBY_VERSION}")
      _(METRICS_DEFAULT_USER_AGENT).must_match(RUBY_PLATFORM)
      _(METRICS_DEFAULT_USER_AGENT).must_match("#{RUBY_ENGINE}/#{RUBY_ENGINE_VERSION}")
    end

    it 'refuses invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new(endpoint: 'not a url')
      end
    end

    it 'uses endpoints path if provided' do
      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(endpoint: 'https://localhost/custom/path')
      _(exp.instance_variable_get(:@path)).must_equal '/custom/path'
    end

    it 'only allows gzip compression or none' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new(compression: 'flate')
      end
      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(compression: nil)
      _(exp.instance_variable_get(:@compression)).must_be_nil

      %w[gzip none].each do |compression|
        exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(compression: compression)
        _(exp.instance_variable_get(:@compression)).must_equal(compression)
      end

      [
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'none' },
        { envar: 'OTEL_EXPORTER_OTLP_METRICS_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_METRICS_COMPRESSION', value: 'none' }
      ].each do |example|
        OpenTelemetry::TestHelpers.with_env(example[:envar] => example[:value]) do
          exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          _(exp.instance_variable_get(:@compression)).must_equal(example[:value])
        end
      end
    end

    it 'sets parameters from the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                                                'OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d',
                                                'OTEL_EXPORTER_OTLP_COMPRESSION' => 'gzip',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
      _(exp.instance_variable_get(:@timeout)).must_equal 11.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/metrics'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/foo/bar'
      _(http.use_ssl?).must_equal true
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.port).must_equal 1234
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                                                'OTEL_EXPORTER_OTLP_HEADERS' => 'a:b,c:d',
                                                'OTEL_EXPORTER_OTLP_COMPRESSION' => 'flate',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true',
                                                'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new(endpoint: 'http://localhost:4321',
                                                           certificate_file: '/baz',
                                                           headers: { 'x' => 'y' },
                                                           compression: 'gzip',
                                                           ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                                           timeout: 12)
      end
      _(exp.instance_variable_get(:@headers)).must_equal('x' => 'y', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
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

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT has a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/'
      ) do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      _(exp.instance_variable_get(:@path)).must_equal '/v1/metrics'
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT does not have a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234'
      ) do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      _(exp.instance_variable_get(:@path)).must_equal '/v1/metrics'
    end

    it 'restricts explicit headers to a String or Hash' do
      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(headers: { 'token' => 'über' })
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(headers: 'token=%C3%BCber')
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

      error = _ do
        exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(headers: Object.new)
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'ignores later mutations of a headers Hash parameter' do
      a_hash_to_mutate_later = { 'token' => 'über' }
      exp = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(headers: a_hash_to_mutate_later)
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

      a_hash_to_mutate_later['token'] = 'unter'
      a_hash_to_mutate_later['oops'] = 'i forgot to add this, too'
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
    end

    describe 'Headers Environment Variable' do
      it 'allows any number of the equal sign (=) characters in the value' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
      end

      it 'trims any leading or trailing whitespaces in keys and values' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
      end

      it 'decodes values as URL encoded UTF-8 strings' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
      end

      it 'appends the default user agent to one provided in config' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'User-Agent=%C3%BCber/3.2.1') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('User-Agent' => "über/3.2.1 #{METRICS_DEFAULT_USER_AGENT}")
      end

      it 'prefers METRICS specific variable' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f', 'OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::MetricsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => METRICS_DEFAULT_USER_AGENT)
      end

      it 'fails fast when header values are missing' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header or values are not found' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header values contain invalid escape characters' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when headers are invalid' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::MetricsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end
    end
  end

  describe 'ssl_verify_mode:' do
    it 'can be set to VERIFY_NONE by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true') do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
    end

    it 'can be set to VERIFY_PEER by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end

    it 'VERIFY_PEER will override VERIFY_NONE' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::MetricsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::OTLP::MetricsExporter.new }
    let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk) }

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      metrics_data = create_metrics_data
      exporter = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(endpoint: 'http://localhost:4318', compression: 'gzip')
      result = exporter.export([metrics_data])
      _(result).must_equal(METRICS_SUCCESS)
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_timeout.then.to_return(status: 200)
      metrics_data = create_metrics_data
      result = exporter.export([metrics_data])
      _(result).must_equal(METRICS_SUCCESS)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)
      metrics_data = create_metrics_data
      result = exporter.export([metrics_data], timeout: 0)
      _(result).must_equal(METRICS_FAILURE)
    end

    it 'returns METRICS_FAILURE on unexpected exceptions' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/metrics').to_raise('something unexpected')
      metrics_data = create_metrics_data
      result = exporter.export([metrics_data], timeout: 1)
      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::MetricsExporter#send_bytes - something unexpected/
      )

      _(result).must_equal(METRICS_FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles encoding failures' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)
      metrics_data = create_metrics_data

      Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.stub(:encode, ->(_) { raise 'a little hell' }) do
        _(exporter.export([metrics_data], timeout: 1)).must_equal(METRICS_FAILURE)
      end

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::MetricsExporter#encode - a little hell/
      )
    ensure
      OpenTelemetry.logger = logger
    end

    it 'returns TIMEOUT on timeout after retrying' do
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_timeout.then.to_raise('this should not be reached')
      metrics_data = create_metrics_data

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      exporter.stub(:backoff?, backoff_stubbed_call) do
        _(exporter.export([metrics_data], timeout: 0.1)).must_equal(METRICS_FAILURE)
      end
    ensure
      @retry_count = 0
    end

    it 'returns METRICS_FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(METRICS_FAILURE)
    end

    it 'returns METRICS_FAILURE when encryption to receiver endpoint fails' do
      exporter = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(endpoint: 'https://localhost:4318/v1/metrics')
      stub_request(:post, 'https://localhost:4318/v1/metrics').to_raise(OpenSSL::SSL::SSLError.new('enigma wedged'))
      metrics_data = create_metrics_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([metrics_data])).must_equal(METRICS_FAILURE)
      end
    end

    it 'exports a metrics_data' do
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)
      metrics_data = create_metrics_data
      result = exporter.export([metrics_data])
      _(result).must_equal(METRICS_SUCCESS)
    end

    it 'handles encoding errors with poise and grace' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)

      ndp = OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new
      ndp.attributes = { 'a' => "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT) }
      ndp.start_time_unix_nano = 0
      ndp.time_unix_nano = 0
      ndp.value = 1

      metrics_data = create_metrics_data(data_points: [ndp])

      result = exporter.export([metrics_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: encoding error for key a and value �/
      )

      _(result).must_equal(METRICS_SUCCESS)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs rpc.Status on bad request' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      details = [::Google::Protobuf::Any.pack(::Google::Protobuf::StringValue.new(value: 'you are a bad request'))]
      status = ::Google::Rpc::Status.encode(::Google::Rpc::Status.new(code: 1, message: 'bad request', details: details))
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 400, body: status, headers: { 'Content-Type' => 'application/x-protobuf' })
      metrics_data = create_metrics_data

      result = exporter.export([metrics_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: OTLP metrics_exporter received rpc.Status{message=bad request, details=\[.*you are a bad request.*\]}/
      )

      _(result).must_equal(METRICS_FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs a specific message when there is a 404' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 404, body: "Not Found\n")
      metrics_data = create_metrics_data

      result = exporter.export([metrics_data])

      _(log_stream.string).must_match(
        %r{ERROR -- : OpenTelemetry error: OTLP metrics_exporter received http\.code=404 for uri: '/v1/metrics'}
      )

      _(result).must_equal(METRICS_FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles Zlib gzip compression errors' do
      stub_request(:post, 'http://localhost:4318/v1/metrics').to_raise(Zlib::DataError.new('data error'))
      metrics_data = create_metrics_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([metrics_data])).must_equal(METRICS_FAILURE)
      end
    end

    it 'exports a metric' do
      stub_post = stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)
      meter_provider.add_metric_reader(exporter)
      meter     = meter_provider.meter('test')
      counter   = meter.create_counter('test_counter', unit: 'smidgen', description: 'a small amount of something')
      counter.add(5, attributes: { 'foo' => 'bar' })
      exporter.pull
      meter_provider.shutdown

      assert_requested(stub_post)
    end

    it 'compresses with gzip if enabled' do
      exporter = OpenTelemetry::Exporter::OTLP::MetricsExporter.new(compression: 'gzip')
      stub_post = stub_request(:post, 'http://localhost:4318/v1/metrics').to_return do |request|
        Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.decode(Zlib.gunzip(request.body))
        { status: 200 }
      end

      metrics_data = create_metrics_data
      result = exporter.export([metrics_data])

      _(result).must_equal(METRICS_SUCCESS)
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      etsr = nil
      stub_post = stub_request(:post, 'http://localhost:4318/v1/metrics').to_return do |request|
        proto = Zlib.gunzip(request.body)
        etsr = Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.decode(proto)
        { status: 200 }
      end

      metrics_data1 = create_metrics_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      metrics_data2 = create_metrics_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([metrics_data1, metrics_data2])

      _(result).must_equal(METRICS_SUCCESS)
      assert_requested(stub_post)
      _(etsr.resource_metrics.length).must_equal(2)
    end

    it 'translates all the things' do
      skip 'Intermittently fails' if RUBY_ENGINE == 'truffleruby'

      stub_request(:post, 'http://localhost:4318/v1/metrics').to_return(status: 200)
      meter_provider.add_metric_reader(exporter)
      meter   = meter_provider.meter('test')
      counter = meter.create_counter('test_counter', unit: 'smidgen', description: 'a small amount of something')
      counter.add(5, attributes: { 'foo' => 'bar' })

      histogram = meter.create_histogram('test_histogram', unit: 'smidgen', description: 'a small amount of something')
      histogram.record(10, attributes: { 'oof' => 'rab' })
      exporter.pull
      meter_provider.shutdown

      encoded_etsr = Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.encode(
        Opentelemetry::Proto::Collector::Metrics::V1::ExportMetricsServiceRequest.new(
          resource_metrics: [
            Opentelemetry::Proto::Metrics::V1::ResourceMetrics.new(
              resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                attributes: [
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: ::OpenTelemetry::SDK::VERSION))
                ]
              ),
              scope_metrics: [
                Opentelemetry::Proto::Metrics::V1::ScopeMetrics.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'test',
                    version: ''
                  ),
                  metrics: [
                    Opentelemetry::Proto::Metrics::V1::Metric.new(
                      name: 'test_counter',
                      description: 'a small amount of something',
                      unit: 'smidgen',
                      sum: Opentelemetry::Proto::Metrics::V1::Sum.new(
                        data_points: [
                          Opentelemetry::Proto::Metrics::V1::NumberDataPoint.new(
                            attributes: [
                              Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'foo', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'bar'))
                            ],
                            as_int: 5,
                            start_time_unix_nano: 1_699_593_427_329_946_585,
                            time_unix_nano: 1_699_593_427_329_946_586,
                            exemplars: nil
                          )
                        ],
                        aggregation_temporality: Opentelemetry::Proto::Metrics::V1::AggregationTemporality::AGGREGATION_TEMPORALITY_DELTA
                      )
                    ),
                    Opentelemetry::Proto::Metrics::V1::Metric.new(
                      name: 'test_histogram',
                      description: 'a small amount of something',
                      unit: 'smidgen',
                      histogram: Opentelemetry::Proto::Metrics::V1::Histogram.new(
                        data_points: [
                          Opentelemetry::Proto::Metrics::V1::HistogramDataPoint.new(
                            attributes: [
                              Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'oof', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'rab'))
                            ],
                            start_time_unix_nano: 1_699_593_427_329_946_585,
                            time_unix_nano: 1_699_593_427_329_946_586,
                            count: 1,
                            sum: 10,
                            bucket_counts: [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
                            explicit_bounds: [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000],
                            exemplars: nil,
                            min: 10,
                            max: 10
                          )
                        ],
                        aggregation_temporality: Opentelemetry::Proto::Metrics::V1::AggregationTemporality::AGGREGATION_TEMPORALITY_DELTA
                      )
                    )
                  ]
                )
              ]
            )
          ]
        )
      )

      assert_requested(:post, 'http://localhost:4318/v1/metrics') do |req|
        req.body == Zlib.gzip(encoded_etsr) # is asserting that the body of the HTTP request is equal to the result of gzipping the encoded_etsr.
      end
    end
  end
end
