# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# require Instrumentation so .install method is found:
require_relative '../../../../../lib/opentelemetry/instrumentation/faraday'
require_relative '../../../../../lib/opentelemetry/instrumentation/faraday/middlewares/tracer_middleware'

describe OpenTelemetry::Instrumentation::Faraday::Middlewares::TracerMiddleware do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  let(:client) do
    ::Faraday.new('http://username:password@example.com') do |builder|
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
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
  end

  after do
    OpenTelemetry.propagation = @orig_propagation
  end

  describe 'first span' do
    before do
      instrumentation.install
    end

    it 'has http 200 attributes' do
      response = client.get('/success')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'has http.status_code 404' do
      response = client.get('/not_found')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 404
      _(span.attributes['http.url']).must_equal 'http://example.com/not_found'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'has http.status_code 500' do
      response = client.get('/failure')

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.status_code']).must_equal 500
      _(span.attributes['http.url']).must_equal 'http://example.com/failure'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'sets the reason phrase' do
      stub_request(:any, 'example.com').to_return(status: [500, 'Internal Server Error'])
      ::Faraday.new('http://example.com').get('/')

      _(span.attributes['http.status_text']).must_equal 'Internal Server Error'
    end

    it 'merges http client attributes' do
      client_context_attrs = {
        'test.attribute' => 'test.value', 'http.method' => 'OVERRIDE'
      }
      response = OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        client.get('/success')
      end

      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'OVERRIDE'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.url']).must_equal 'http://example.com/success'
      _(span.attributes['test.attribute']).must_equal 'test.value'
      _(response.env.request_headers['Traceparent']).must_equal(
        "00-#{span.hex_trace_id}-#{span.hex_span_id}-01"
      )
    end

    it 'accepts peer service name from config' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client.get('/success')

      _(span.attributes['peer.service']).must_equal 'example:faraday'
    end

    it 'prioritizes context attributes over config for peer service name' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(peer_service: 'example:faraday')

      client_context_attrs = { 'peer.service' => 'example:custom' }
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        client.get('/success')
      end

      _(span.attributes['peer.service']).must_equal 'example:custom'
    end
  end
end
