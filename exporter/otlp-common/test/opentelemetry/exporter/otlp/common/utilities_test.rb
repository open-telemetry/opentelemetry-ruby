# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::Common::Utilities do
  describe 'IPv4/IPv6 compatibility' do
    it 'handles IPv6 loopback address with brackets' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://[::1]:4318/v1/logs')
      _(exp.host).must_equal '[::1]'
      _(exp.port).must_equal 4318
      _(exp.path).must_equal '/v1/logs'
    end

    it 'handles IPv6 full address with brackets' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://[2001:db8::1]:4318/v1/logs')
      _(exp.host).must_equal '[2001:db8::1]'
      _(exp.port).must_equal 4318
    end

    it 'handles IPv6 address with https' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('https://[::1]:4318/v1/logs')
      _(exp.host).must_equal '[::1]'
      _(exp.port).must_equal 4318
      _(exp.scheme).must_equal 'https'
    end

    it 'handles IPv6 address with custom path' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://[::1]:8080/custom/path')
      _(exp.host).must_equal '[::1]'
      _(exp.port).must_equal 8080
      _(exp.path).must_equal '/custom/path'
    end

    it 'handles IPv4 loopback address' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://127.0.0.1:4318/v1/logs')
      _(exp.host).must_equal '127.0.0.1'
      _(exp.port).must_equal 4318
      _(exp.path).must_equal '/v1/logs'
    end

    it 'handles IPv4 address with custom port' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://192.168.1.100:8080/v1/logs')
      _(exp.host).must_equal '192.168.1.100'
      _(exp.port).must_equal 8080
    end

    it 'handles IPv4 address with https' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('https://10.0.0.1:4318/v1/logs')
      _(exp.host).must_equal '10.0.0.1'
      _(exp.port).must_equal 4318
      _(exp.scheme).must_equal 'https'
    end

    it 'handles IPv4 address with custom path' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://127.0.0.1:9090/custom/path')
      _(exp.host).must_equal '127.0.0.1'
      _(exp.port).must_equal 9090
      _(exp.path).must_equal '/custom/path'
    end

    it 'handles IPv4 address from environment variable' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://192.168.1.1:4318') do
        OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri(nil, 'v1/logs', 'OTEL_EXPORTER_OTLP_LOGS_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT')
      end
      _(exp.host).must_equal '192.168.1.1'
      _(exp.port).must_equal 4318
      _(exp.path).must_equal '/v1/logs'
    end

    it 'handles hostnames' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://localhost:4318/v1/logs')
      _(exp.host).must_equal 'localhost'
      _(exp.port).must_equal 4318
    end

    it 'handles fully qualified domain names' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('http://otel.example.com:4318/v1/logs')
      _(exp.host).must_equal 'otel.example.com'
      _(exp.port).must_equal 4318
    end

    it 'handles hostnames with https' do
      exp = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri('https://otel-collector.prod.example.com:443/v1/logs')
      _(exp.host).must_equal 'otel-collector.prod.example.com'
      _(exp.port).must_equal 443
      _(exp.scheme).must_equal 'https'
    end

    it 'handles IPv6 address from environment variable' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_ENDPOINT' => 'http://[::1]:4318') do
        OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri(nil, 'v1/logs', 'OTEL_EXPORTER_OTLP_LOGS_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT')
      end
      _(exp.host).must_equal '[::1]'
      _(exp.port).must_equal 4318
      _(exp.path).must_equal '/v1/logs'
    end
  end
end
