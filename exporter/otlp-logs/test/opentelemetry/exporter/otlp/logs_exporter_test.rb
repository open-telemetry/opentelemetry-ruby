# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'google/protobuf/wrappers_pb'
require 'google/protobuf/well_known_types'

describe OpenTelemetry::Exporter::OTLP::LogsExporter do
  SUCCESS = OpenTelemetry::SDK::Logs::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Logs::Export::FAILURE
  VERSION = OpenTelemetry::Exporter::OTLP::VERSION
  DEFAULT_USER_AGENT = OpenTelemetry::Exporter::OTLP::LogsExporter::DEFAULT_USER_AGENT
  CLIENT_CERT_A_PATH = File.dirname(__FILE__) + '/mtls-client-a.pem'
  CLIENT_CERT_A = OpenSSL::X509::Certificate.new(File.read(CLIENT_CERT_A_PATH))
  CLIENT_KEY_A = OpenSSL::PKey::RSA.new(File.read(CLIENT_CERT_A_PATH))
  CLIENT_CERT_B_PATH = File.dirname(__FILE__) + '/mtls-client-b.pem'
  CLIENT_CERT_B = OpenSSL::X509::Certificate.new(File.read(CLIENT_CERT_B_PATH))
  CLIENT_KEY_B = OpenSSL::PKey::RSA.new(File.read(CLIENT_CERT_B_PATH))

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new
      _(exp).wont_be_nil
      _(exp.instance_variable_get(:@headers)).must_equal('User-Agent' => DEFAULT_USER_AGENT)
      _(exp.instance_variable_get(:@timeout)).must_equal 10.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/logs'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_be_nil
      _(http.cert).must_be_nil
      _(http.key).must_be_nil
      _(http.use_ssl?).must_equal false
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
      _(http.port).must_equal 4318
    end

    it 'provides a useful, spec-compliant default user agent header' do
      # spec compliance: OTLP Exporter name and version
      _(DEFAULT_USER_AGENT).must_match("OTel-OTLP-Exporter-Ruby/#{VERSION}")
      # bonus: incredibly useful troubleshooting information
      _(DEFAULT_USER_AGENT).must_match("Ruby/#{RUBY_VERSION}")
      _(DEFAULT_USER_AGENT).must_match(RUBY_PLATFORM)
      _(DEFAULT_USER_AGENT).must_match("#{RUBY_ENGINE}/#{RUBY_ENGINE_VERSION}")
    end

    it 'refuses invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new(endpoint: 'not a url')
      end
    end

    it 'uses endpoints path if provided' do
      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(endpoint: 'https://localhost/custom/path')
      _(exp.instance_variable_get(:@path)).must_equal '/custom/path'
    end

    it 'only allows gzip compression or none' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new(compression: 'flate')
      end
      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(compression: nil)
      _(exp.instance_variable_get(:@compression)).must_be_nil

      %w[gzip none].each do |compression|
        exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(compression: compression)
        _(exp.instance_variable_get(:@compression)).must_equal(compression)
      end

      [
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_COMPRESSION', value: 'none' },
        { envar: 'OTEL_EXPORTER_OTLP_LOGS_COMPRESSION', value: 'gzip' },
        { envar: 'OTEL_EXPORTER_OTLP_LOGS_COMPRESSION', value: 'none' }
      ].each do |example|
        OpenTelemetry::TestHelpers.with_env(example[:envar] => example[:value]) do
          exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new
          _(exp.instance_variable_get(:@compression)).must_equal(example[:value])
        end
      end
    end

    it 'sets parameters from the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar/cacert',
                                                'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE' => CLIENT_CERT_A_PATH,
                                                'OTEL_EXPORTER_OTLP_CLIENT_KEY' => CLIENT_CERT_A_PATH,
                                                'OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d',
                                                'OTEL_EXPORTER_OTLP_COMPRESSION' => 'gzip',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'User-Agent' => DEFAULT_USER_AGENT)
      _(exp.instance_variable_get(:@timeout)).must_equal 11.0
      _(exp.instance_variable_get(:@path)).must_equal '/v1/logs'
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/foo/bar/cacert'
      # Quality check fails in JRuby
      _(http.cert).must_equal CLIENT_CERT_A unless RUBY_ENGINE == 'jruby'
      _(http.key.params).must_equal CLIENT_KEY_A.params
      _(http.use_ssl?).must_equal true
      _(http.address).must_equal 'localhost'
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.port).must_equal 1234
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234',
                                                'OTEL_EXPORTER_OTLP_CERTIFICATE' => '/foo/bar',
                                                'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE' => CLIENT_CERT_A_PATH,
                                                'OTEL_EXPORTER_OTLP_CLIENT_KEY' => CLIENT_CERT_A_PATH,
                                                'OTEL_EXPORTER_OTLP_HEADERS' => 'a:b,c:d',
                                                'OTEL_EXPORTER_OTLP_COMPRESSION' => 'flate',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true',
                                                'OTEL_EXPORTER_OTLP_TIMEOUT' => '11') do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new(endpoint: 'http://localhost:4321',
                                                        certificate_file: '/baz',
                                                        client_certificate_file: CLIENT_CERT_B_PATH,
                                                        client_key_file: CLIENT_CERT_B_PATH,
                                                        headers: { 'x' => 'y' },
                                                        compression: 'gzip',
                                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                                        timeout: 12)
      end
      _(exp.instance_variable_get(:@headers)).must_equal('x' => 'y', 'User-Agent' => DEFAULT_USER_AGENT)
      _(exp.instance_variable_get(:@timeout)).must_equal 12.0
      _(exp.instance_variable_get(:@path)).must_equal ''
      _(exp.instance_variable_get(:@compression)).must_equal 'gzip'
      http = exp.instance_variable_get(:@http)
      _(http.ca_file).must_equal '/baz'
      # equality check fails in JRuby
      _(http.cert).must_equal CLIENT_CERT_B unless RUBY_ENGINE == 'jruby'
      _(http.key.params).must_equal CLIENT_KEY_B.params
      _(http.use_ssl?).must_equal false
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4321
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT has a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234/'
      ) do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      _(exp.instance_variable_get(:@path)).must_equal '/v1/logs'
    end

    it 'appends the correct path if OTEL_EXPORTER_OTLP_ENDPOINT does not have a trailing slash' do
      exp = OpenTelemetry::TestHelpers.with_env(
        'OTEL_EXPORTER_OTLP_ENDPOINT' => 'https://localhost:1234'
      ) do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      _(exp.instance_variable_get(:@path)).must_equal '/v1/logs'
    end

    it 'restricts explicit headers to a String or Hash' do
      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(headers: { 'token' => 'über' })
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)

      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(headers: 'token=%C3%BCber')
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)

      error = _ do
        exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(headers: Object.new)
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über')
      end.must_raise(ArgumentError)
      _(error.message).must_match(/headers/i)
    end

    it 'ignores later mutations of a headers Hash parameter' do
      a_hash_to_mutate_later = { 'token' => 'über' }
      exp = OpenTelemetry::Exporter::OTLP::LogsExporter.new(headers: a_hash_to_mutate_later)
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)

      a_hash_to_mutate_later['token'] = 'unter'
      a_hash_to_mutate_later['oops'] = 'i forgot to add this, too'
      _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)
    end

    describe 'Headers Environment Variable' do
      it 'allows any number of the equal sign (=) characters in the value' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f', 'User-Agent' => DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'a=b,c=d==,e=f') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd==', 'e' => 'f', 'User-Agent' => DEFAULT_USER_AGENT)
      end

      it 'trims any leading or trailing whitespaces in keys and values' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f', 'User-Agent' => DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'a =  b  ,c=d , e=f') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('a' => 'b', 'c' => 'd', 'e' => 'f', 'User-Agent' => DEFAULT_USER_AGENT)
      end

      it 'decodes values as URL encoded UTF-8 strings' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token', 'User-Agent' => DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)

        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => '%C3%BCber=token') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('über' => 'token', 'User-Agent' => DEFAULT_USER_AGENT)
      end

      it 'appends the default user agent to one provided in config' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'User-Agent=%C3%BCber/3.2.1') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('User-Agent' => "über/3.2.1 #{DEFAULT_USER_AGENT}")
      end

      it 'prefers LOGS specific variable' do
        exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a=b,c=d==,e=f', 'OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'token=%C3%BCber') do
          OpenTelemetry::Exporter::OTLP::LogsExporter.new
        end
        _(exp.instance_variable_get(:@headers)).must_equal('token' => 'über', 'User-Agent' => DEFAULT_USER_AGENT)
      end

      it 'fails fast when header values are missing' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'a = ') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header or values are not found' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => ',') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when header values contain invalid escape characters' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'c=hi%F3') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end

      it 'fails fast when headers are invalid' do
        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)

        error = _ do
          OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_LOGS_HEADERS' => 'this is not a header') do
            OpenTelemetry::Exporter::OTLP::LogsExporter.new
          end
        end.must_raise(ArgumentError)
        _(error.message).must_match(/headers/i)
      end
    end
  end

  describe 'ssl_verify_mode:' do
    it 'can be set to VERIFY_NONE by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true') do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_NONE
    end

    it 'can be set to VERIFY_PEER by an envvar' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end

    it 'VERIFY_PEER will override VERIFY_NONE' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE' => 'true',
                                                'OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER' => 'true') do
        OpenTelemetry::Exporter::OTLP::LogsExporter.new
      end
      http = exp.instance_variable_get(:@http)
      _(http.verify_mode).must_equal OpenSSL::SSL::VERIFY_PEER
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::OTLP::LogsExporter.new }
    # TODO: replace with a before block to set a global logger provider through OpenTelemetry.logger_provider when the API code is merged
    let(:logger_provider) { OpenTelemetry::SDK::Logs::LoggerProvider.new(resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk) }

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      exporter = OpenTelemetry::Exporter::OTLP::LogsExporter.new(endpoint: 'http://localhost:4318', compression: 'gzip')
      result = exporter.export([log_record_data])
      _(result).must_equal(SUCCESS)
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_timeout.then.to_return(status: 200)
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      result = exporter.export([log_record_data])
      _(result).must_equal(SUCCESS)
    end

    it 'returns FAILURE on timeout' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      result = exporter.export([log_record_data], timeout: 0)
      _(result).must_equal(FAILURE)
    end

    it 'returns FAILURE on unexpected exceptions' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/logs').to_raise('something unexpected')
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      result = exporter.export([log_record_data], timeout: 1)

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

      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data

      Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.stub(:encode, ->(_) { raise 'a little hell' }) do
        _(exporter.export([log_record_data], timeout: 1)).must_equal(FAILURE)
      end

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: unexpected error in OTLP::Exporter#encode - a little hell/
      )
    ensure
      OpenTelemetry.logger = logger
    end

    { 'Net::HTTPServiceUnavailable' => 503,
      'Net::HTTPTooManyRequests' => 429,
      'Net::HTTPRequestTimeout' => 408,
      'Net::HTTPGatewayTimeout' => 504,
      'Net::HTTPBadGateway' => 502,
      'Net::HTTPNotFound' => 404 }.each do |klass, code|
      it "logs an error and returns FAILURE with #{code}s" do
        OpenTelemetry::Exporter::OTLP::LogsExporter.stub_const(:RETRY_COUNT, 0) do
          log_stream = StringIO.new
          OpenTelemetry.logger = ::Logger.new(log_stream)

          stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: code)
          log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
          _(exporter.export([log_record_data])).must_equal(FAILURE)
          _(log_stream.string).must_match(
            %r{ERROR -- : OpenTelemetry error: OTLP logs exporter received #{klass}, http.code=#{code}, for uri: '/v1/logs'}
          )
        end
      end
    end

    [
      Net::OpenTimeout,
      Net::ReadTimeout,
      OpenSSL::SSL::SSLError,
      SocketError,
      EOFError,
      Zlib::DataError
    ].each do |error|
      it "logs error and returns FAILURE when #{error} is raised" do
        OpenTelemetry::Exporter::OTLP::LogsExporter.stub_const(:RETRY_COUNT, 0) do
          log_stream = StringIO.new
          OpenTelemetry.logger = ::Logger.new(log_stream)

          stub_request(:post, 'http://localhost:4318/v1/logs').to_raise(error.send(:new))
          log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
          _(exporter.export([log_record_data])).must_equal(FAILURE)
          _(log_stream.string).must_match(
            /ERROR -- : OpenTelemetry error: #{error}/
          )
        end
      end
    end

    it 'works with a SystemCallError' do
      OpenTelemetry::Exporter::OTLP::LogsExporter.stub_const(:RETRY_COUNT, 0) do
        log_stream = StringIO.new
        OpenTelemetry.logger = ::Logger.new(log_stream)
        stub_request(:post, 'http://localhost:4318/v1/logs').to_raise(SystemCallError.new('Failed to open TCP connection', 61))
        log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
        _(exporter.export([log_record_data])).must_equal(FAILURE)
        _(log_stream.string).must_match(
          /ERROR -- : OpenTelemetry error:.*Failed to open TCP connection/
        )
      end
    end

    it 'returns FAILURE on timeout after retrying' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_timeout.then.to_raise('this should not be reached')
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      exporter.stub(:backoff?, backoff_stubbed_call) do
        _(exporter.export([log_record_data], timeout: 0.1)).must_equal(FAILURE)
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
      log_stream = StringIO.new
      OpenTelemetry.logger = ::Logger.new(log_stream)

      exporter = OpenTelemetry::Exporter::OTLP::LogsExporter.new(endpoint: 'https://localhost:4318/v1/logs')
      stub_request(:post, 'https://localhost:4318/v1/logs').to_raise(OpenSSL::SSL::SSLError.new('enigma wedged'))
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([log_record_data])).must_equal(FAILURE)

        _(log_stream.string).must_match(
          /ERROR -- : OpenTelemetry error: enigma wedged/
        )
      end
    end

    it 'exports a log_record_data' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      result = exporter.export([log_record_data])
      _(result).must_equal(SUCCESS)
    end

    it 'handles encoding errors with poise and grace' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data(total_recorded_attributes: 1, attributes: { 'a' => "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT) })

      result = exporter.export([log_record_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: encoding error for key a and value �/
      )

      _(result).must_equal(SUCCESS)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs rpc.Status on bad request' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      details = [::Google::Protobuf::Any.pack(::Google::Protobuf::StringValue.new(value: 'you are a bad request'))]
      status = ::Google::Rpc::Status.encode(::Google::Rpc::Status.new(code: 1, message: 'bad request', details: details))
      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 400, body: status, headers: { 'Content-Type' => 'application/x-protobuf' })
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data

      result = exporter.export([log_record_data])

      _(log_stream.string).must_match(
        /ERROR -- : OpenTelemetry error: OTLP logs exporter received rpc.Status{message=bad request, details=\[.*you are a bad request.*\]}/
      )

      _(result).must_equal(FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'logs a specific message when there is a 404' do
      log_stream = StringIO.new
      logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(log_stream)

      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 404, body: "Not Found\n")
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data

      result = exporter.export([log_record_data])

      _(log_stream.string).must_match(
        %r{ERROR -- : OpenTelemetry error: OTLP logs exporter received Net::HTTPNotFound, http.code=404, for uri: '/v1/logs'\n}
      )

      _(result).must_equal(FAILURE)
    ensure
      OpenTelemetry.logger = logger
    end

    it 'handles Zlib gzip compression errors' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_raise(Zlib::DataError.new('data error'))
      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      exporter.stub(:backoff?, ->(**_) { false }) do
        _(exporter.export([log_record_data])).must_equal(FAILURE)
      end
    end

    it 'exports a log record from a logger' do
      stub_post = stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(exporter, max_queue_size: 1, max_export_batch_size: 1)
      logger_provider.add_log_record_processor(processor)
      logger_provider.logger(name: 'test').on_emit(body: 'test')
      logger_provider.shutdown
      assert_requested(stub_post)
    end

    it 'compresses with gzip if enabled' do
      exporter = OpenTelemetry::Exporter::OTLP::LogsExporter.new(compression: 'gzip')
      stub_post = stub_request(:post, 'http://localhost:4318/v1/logs').to_return do |request|
        Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.decode(Zlib.gunzip(request.body))
        { status: 200 }
      end

      log_record_data = OpenTelemetry::TestHelpers.create_log_record_data
      result = exporter.export([log_record_data])

      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      etsr = nil
      stub_post = stub_request(:post, 'http://localhost:4318/v1/logs').to_return do |request|
        proto = Zlib.gunzip(request.body)
        etsr = Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.decode(proto)
        { status: 200 }
      end

      log_record_data1 = OpenTelemetry::TestHelpers.create_log_record_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      log_record_data2 = OpenTelemetry::TestHelpers.create_log_record_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([log_record_data1, log_record_data2])

      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
      _(etsr.resource_logs.length).must_equal(2)
    end

    it 'translates all the things' do
      stub_request(:post, 'http://localhost:4318/v1/logs').to_return(status: 200)
      processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(exporter)
      logger = logger_provider.logger(name: 'logger', version: 'v0.0.1')
      other_logger = logger_provider.logger(name: 'other_logger', version: 'v0.1.0')

      lr1 = {
        timestamp: Time.now,
        observed_timestamp: Time.now + 1,
        severity_text: 'DEBUG',
        severity_number: 5,
        body: 'log_1',
        attributes: { 'b' => true },
        trace_id: OpenTelemetry::Trace.generate_trace_id,
        span_id: OpenTelemetry::Trace.generate_span_id,
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
        context: OpenTelemetry::Context.current
      }

      lr2 = {
        timestamp: Time.now + 2,
        observed_timestamp: Time.now + 3,
        severity_text: 'WARN',
        severity_number: 13,
        body: 'log_1',
        attributes: { 'a' => false },
        trace_id: OpenTelemetry::Trace.generate_trace_id,
        span_id: OpenTelemetry::Trace.generate_span_id,
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
        context: OpenTelemetry::Context.current
      }

      lr3 = {
        timestamp: Time.now + 4,
        observed_timestamp: Time.now + 5,
        severity_text: 'ERROR',
        severity_number: 17,
        body: 'log_1',
        attributes: { 'c' => 12_345 },
        trace_id: OpenTelemetry::Trace.generate_trace_id,
        span_id: OpenTelemetry::Trace.generate_span_id,
        trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT,
        context: OpenTelemetry::Context.current
      }

      logger_provider.add_log_record_processor(processor)
      logger.on_emit(**lr1)
      logger.on_emit(**lr2)
      other_logger.on_emit(**lr3)
      logger_provider.shutdown
      encoded_etsr = Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.encode(
        Opentelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest.new(
          resource_logs: [
            Opentelemetry::Proto::Logs::V1::ResourceLogs.new(
              resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                attributes: [
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: OpenTelemetry::SDK::VERSION))
                ]
              ),
              scope_logs: [
                Opentelemetry::Proto::Logs::V1::ScopeLogs.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'logger',
                    version: 'v0.0.1'
                  ),
                  log_records: [
                    Opentelemetry::Proto::Logs::V1::LogRecord.new(
                      time_unix_nano: (lr1[:timestamp].to_r * 1_000_000_000).to_i,
                      observed_time_unix_nano: (lr1[:observed_timestamp].to_r * 1_000_000_000).to_i,
                      severity_number: 5,
                      severity_text: lr1[:severity_text],
                      body: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: lr1[:body]),
                      attributes: [
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'b', value: Opentelemetry::Proto::Common::V1::AnyValue.new(bool_value: true))
                      ],
                      dropped_attributes_count: 0,
                      flags: lr1[:trace_flags].instance_variable_get(:@flags),
                      trace_id: lr1[:trace_id],
                      span_id: lr1[:span_id]
                    ),
                    Opentelemetry::Proto::Logs::V1::LogRecord.new(
                      time_unix_nano: (lr2[:timestamp].to_r * 1_000_000_000).to_i,
                      observed_time_unix_nano: (lr2[:observed_timestamp].to_r * 1_000_000_000).to_i,
                      severity_number: 13,
                      severity_text: lr2[:severity_text],
                      body: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: lr2[:body]),
                      attributes: [
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'a', value: Opentelemetry::Proto::Common::V1::AnyValue.new(bool_value: false))
                      ],
                      dropped_attributes_count: 0,
                      flags: lr2[:trace_flags].instance_variable_get(:@flags),
                      trace_id: lr2[:trace_id],
                      span_id: lr2[:span_id]
                    )
                  ]
                ),
                Opentelemetry::Proto::Logs::V1::ScopeLogs.new(
                  scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                    name: 'other_logger',
                    version: 'v0.1.0'
                  ),
                  log_records: [
                    Opentelemetry::Proto::Logs::V1::LogRecord.new(
                      time_unix_nano: (lr3[:timestamp].to_r * 1_000_000_000).to_i,
                      observed_time_unix_nano: (lr3[:observed_timestamp].to_r * 1_000_000_000).to_i,
                      severity_number: 17,
                      severity_text: lr3[:severity_text],
                      body: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: lr3[:body]),
                      attributes: [
                        Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'c', value: Opentelemetry::Proto::Common::V1::AnyValue.new(int_value: 12_345))
                      ],
                      dropped_attributes_count: 0,
                      flags: lr3[:trace_flags].instance_variable_get(:@flags),
                      trace_id: lr3[:trace_id],
                      span_id: lr3[:span_id]
                    )
                  ]
                )
              ]
            )
          ]
        )
      )

      assert_requested(:post, 'http://localhost:4318/v1/logs') do |req|
        req.body == Zlib.gzip(encoded_etsr)
      end
    end
  end
end
