# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/adapters/net/http'
require_relative '../../../../../lib/opentelemetry/adapters/net/http/patches/instrumentation'

describe OpenTelemetry::Adapters::Net::HTTP::Adapter do
  let(:adapter) { OpenTelemetry::Adapters::Net::HTTP::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout

    # this is currently a noop but this will future proof the test
    @orig_propagator = OpenTelemetry.propagation.http
    propagator = OpenTelemetry::Context::Propagation::Propagator.new(
      OpenTelemetry::Trace::Propagation::TraceContext.text_injector,
      OpenTelemetry::Trace::Propagation::TraceContext.text_extractor
    )
    OpenTelemetry.propagation.http = propagator
  end

  after do
    # Force re-install of instrumentation
    adapter.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation.http = @orig_propagator
  end

  describe 'tracing' do
    before do
      adapter.install
    end

    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    it 'after request with success code' do
      ::Net::HTTP.get('example.com', '/success')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['peer.hostname']).must_equal 'example.com'
      _(span.attributes['peer.port']).must_equal 80
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01" }
      )
    end

    it 'after request with failure code' do
      ::Net::HTTP.post(URI('http://example.com/failure'), 'q' => 'ruby')

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP POST'
      _(span.attributes['http.method']).must_equal 'POST'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.target']).must_equal '/failure'
      _(span.attributes['peer.hostname']).must_equal 'example.com'
      _(span.attributes['peer.port']).must_equal 80
      assert_requested(
        :post,
        'http://example.com/failure',
        headers: { 'Traceparent' => "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        ::Net::HTTP.get(URI('https://example.com/timeout'))
      end.must_raise Net::OpenTimeout

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'https'
      _(span.attributes['http.status_code']).must_be_nil
      _(span.attributes['http.target']).must_equal '/timeout'
      _(span.attributes['peer.hostname']).must_equal 'example.com'
      _(span.attributes['peer.port']).must_equal 443
      _(span.status.canonical_code).must_equal(
        OpenTelemetry::Trace::Status::UNKNOWN_ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: Net::OpenTimeout'
      )
      assert_requested(
        :get,
        'https://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01" }
      )
    end
  end
end
