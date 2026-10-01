
# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

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
end
