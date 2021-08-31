# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/faraday/instrumentation'

describe OpenTelemetry::Instrumentation::Faraday do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    instrumentation.install
    exporter.reset
  end

  describe 'instrumentation' do
    let(:middleware) { ::Faraday::Middleware.lookup_middleware(:open_telemetry) }

    it 'includes the tracer middleware' do
      conn = ::Faraday.new('http://example.com')
      _(conn.builder.handlers.map(&:klass)).must_include middleware
    end

    it 'positions the tracer middleware first in the list of handlers' do
      conn = ::Faraday.new('http://example.com') do |f|
        f.request :authorization, :Bearer, 'abc123'
        f.request :instrumentation
      end
      _(conn.builder.handlers.first.klass).must_equal middleware
    end
  end

  describe 'tracing' do
    before do
      stub_request(:any, 'example.com')
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request' do
      ::Faraday.new('http://example.com').get('/')

      _(exporter.finished_spans.size).must_equal 1
    end
  end
end
