# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/http'
require_relative '../../../../lib/opentelemetry/instrumentation/http/patches/client'

describe OpenTelemetry::Instrumentation::HTTP::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::HTTP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }

  before do
    exporter.reset
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    instrumentation.install(hide_query_params: true)
    stub_request(:get, 'http://example.com/success').to_return(status: 200)
    stub_request(:post, 'http://example.com/failure').to_return(status: 500)
    stub_request(:get, 'https://example.com/timeout').to_timeout
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe '#perform' do
    it 'traces a simple request' do
      ::HTTP.get('http://example.com/success')

      _(exporter.finished_spans.size).must_equal(1)
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
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request with failure code' do
      ::HTTP.post('http://example.com/failure')

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
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'after request timeout' do
      expect do
        ::HTTP.get('https://example.com/timeout')
      end.must_raise HTTP::TimeoutError

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'https'
      _(span.attributes['http.status_code']).must_be_nil
      _(span.attributes['http.target']).must_equal '/timeout'
      _(span.attributes['peer.hostname']).must_equal 'example.com'
      _(span.attributes['peer.port']).must_equal 443
      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.status.description).must_equal(
        'Unhandled exception of type: HTTP::TimeoutError'
      )
      assert_requested(
        :get,
        'https://example.com/timeout',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'merges http client attributes' do
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('peer.service' => 'foo') do
        ::HTTP.get('http://example.com/success')
      end

      _(exporter.finished_spans.size).must_equal 1
      _(span.name).must_equal 'HTTP GET'
      _(span.attributes['http.method']).must_equal 'GET'
      _(span.attributes['http.scheme']).must_equal 'http'
      _(span.attributes['http.status_code']).must_equal 200
      _(span.attributes['http.target']).must_equal '/success'
      _(span.attributes['peer.hostname']).must_equal 'example.com'
      _(span.attributes['peer.port']).must_equal 80
      _(span.attributes['peer.service']).must_equal 'foo'
      assert_requested(
        :get,
        'http://example.com/success',
        headers: { 'Traceparent' => "00-#{span.hex_trace_id}-#{span.hex_span_id}-01" }
      )
    end

    it 'hide query params if enabled' do
      stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
      ::HTTP.get('http://example.com/success?foo=bar')

      _(exporter.finished_spans.size).must_equal(1)
      _(span.attributes['http.target']).must_equal '/success?'
    end

    it 'show query params if disabled' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(hide_query_params: false)
      stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
      ::HTTP.get('http://example.com/success?foo=bar')

      _(exporter.finished_spans.size).must_equal(1)
      _(span.attributes['http.target']).must_equal '/success?foo=bar'
    end

    it 'show query params if disabled via environment variable' do
      with_env('OTEL_RUBY_INSTRUMENTATION_HTTP_HIDE_QUERY_PARAMS' => 'false') do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install
        stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
        ::HTTP.get('http://example.com/success?foo=bar')

        _(exporter.finished_spans.size).must_equal(1)
        _(span.attributes['http.target']).must_equal '/success?foo=bar'
      end
    end

    it 'hides query params if enabled via environment variable' do
      with_env('OTEL_RUBY_INSTRUMENTATION_HTTP_HIDE_QUERY_PARAMS' => 'true') do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install
        stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
        ::HTTP.get('http://example.com/success?foo=bar')

        _(exporter.finished_spans.size).must_equal(1)
        _(span.attributes['http.target']).must_equal '/success?'
      end
    end

    it 'overrides local config value when local config is disabled' do
      with_env('OTEL_RUBY_INSTRUMENTATION_HTTP_HIDE_QUERY_PARAMS' => 'true') do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(hide_query_params: false)
        stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
        ::HTTP.get('http://example.com/success?foo=bar')

        _(exporter.finished_spans.size).must_equal(1)
        _(span.attributes['http.target']).must_equal '/success?'
      end
    end

    it 'overrides local config value when local config is enabled' do
      with_env('OTEL_RUBY_INSTRUMENTATION_HTTP_HIDE_QUERY_PARAMS' => 'false') do
        instrumentation.instance_variable_set(:@installed, false)
        instrumentation.install(hide_query_params: true)
        stub_request(:get, 'http://example.com/success?foo=bar').to_return(status: 200)
        ::HTTP.get('http://example.com/success?foo=bar')

        _(exporter.finished_spans.size).must_equal(1)
        _(span.attributes['http.target']).must_equal '/success?foo=bar'
      end
    end
  end

  def with_env(new_env)
    env_to_reset = ENV.select { |k, _| new_env.key?(k) }
    keys_to_delete = new_env.keys - ENV.keys
    new_env.each_pair { |k, v| ENV[k] = v }
    yield
    env_to_reset.each_pair { |k, v| ENV[k] = v }
    keys_to_delete.each { |k| ENV.delete(k) }
  end
end
