# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/adapters/restclient'
require_relative '../../../../lib/opentelemetry/adapters/restclient/patches/request'

describe OpenTelemetry::Adapters::RestClient::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::RestClient::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:get, 'http://example.com/failure').to_return(status: 500)

    # these are currently empty, but this will future proof the test
    @orig_injectors = OpenTelemetry.propagation.http_injectors
    OpenTelemetry.propagation.http_injectors = [
      OpenTelemetry::Trace::Propagation::TraceContext.http_trace_context_injector
    ]
  end

  after do
    # Force re-install of instrumentation
    adapter.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation.http_injectors = @orig_injectors
  end

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      ::RestClient.get('http://example.com/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['component']).must_equal 'http'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.trace_id}-#{span.span_id}-01" }
      )
    end

    it 'after request with failure code' do
      expect do
        ::RestClient.get('http://example.com/failure')
      end.must_raise RestClient::InternalServerError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['component']).must_equal 'http'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      assert_requested(
        :get,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.trace_id}-#{span.span_id}-01" }
      )
    end
  end
end
