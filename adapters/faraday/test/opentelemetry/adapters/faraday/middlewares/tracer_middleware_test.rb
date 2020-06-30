# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Adapter so .install method is found:
require_relative '../../../../../lib/opentelemetry/adapters/faraday'
require_relative '../../../../../lib/opentelemetry/adapters/faraday/middlewares/tracer_middleware'

describe OpenTelemetry::Adapters::Faraday::Middlewares::TracerMiddleware do
  let(:adapter) { OpenTelemetry::Adapters::Faraday::Adapter.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  let(:client) do
    ::Faraday.new('http://example.com') do |builder|
      builder.adapter(:test) do |stub|
        stub.get('/success') { |_| [200, {}, 'OK'] }
        stub.get('/failure') { |_| [500, {}, 'OK'] }
        stub.get('/not_found') { |_| [404, {}, 'OK'] }
      end
    end
  end

  before do
    exporter.reset

    # this is currently a noop but this will future proof the test
    @orig_propagator = OpenTelemetry.propagation.http
    propagator = OpenTelemetry::Context::Propagation::Propagator.new(
      OpenTelemetry::Trace::Propagation::TraceContext.text_injector,
      OpenTelemetry::Trace::Propagation::TraceContext.text_extractor
    )
    OpenTelemetry.propagation.http = propagator
  end

  after do
    OpenTelemetry.propagation.http = @orig_propagator
  end

  describe 'first span' do
    before do
      adapter.install
    end

    it 'has http 200 attributes' do
      response = client.get('/success')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
      )
    end

    it 'has http.status_code 404' do
      response = client.get('/not_found')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 404
      _(span.attributes['http.url']).must_equal 'http://example.com/not_found'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
      )
    end

    it 'has http.status_code 500' do
      response = client.get('/failure')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.trace_id.unpack1('H*')}-#{span.span_id.unpack1('H*')}-01"
      )
    end
  end
end
