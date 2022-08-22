# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT = 'http://localhost:9411/api/v2/spans'

describe OpenTelemetry::Exporter::Zipkin::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
  TIMEOUT = OpenTelemetry::SDK::Trace::Export::TIMEOUT

  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::Zipkin::Exporter.new
      _(exp).wont_be_nil

      headers = exp.instance_variable_get(:@headers)
      http = exp.instance_variable_get(:@http)
      assert_nil(headers)
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 9_411
    end

    it 'refuses an invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::Zipkin::Exporter.new(endpoint: 'not a url')
      end
    end

    it 'uses endpoints path if provided' do
      exp = OpenTelemetry::Exporter::Zipkin::Exporter.new(endpoint: 'https://localhost/custom/path')
      _(exp.instance_variable_get(:@path)).must_equal '/custom/path'
    end

    it 'sets parameters from the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_ZIPKIN_ENDPOINT' => 'http://127.0.0.1:1234',
                                                'OTEL_EXPORTER_ZIPKIN_TRACES_HEADERS' => 'foo=bar,c=d',
                                                'OTEL_EXPORTER_ZIPKIN_TRACES_TIMEOUT' => '20') do
        OpenTelemetry::Exporter::Zipkin::Exporter.new
      end
      timeout = exp.instance_variable_get(:@timeout)
      headers = exp.instance_variable_get(:@headers)
      http = exp.instance_variable_get(:@http)
      _(headers).must_include 'foo'
      _(headers['foo']).must_equal 'bar'
      _(http.address).must_equal '127.0.0.1'
      _(http.port).must_equal 1_234
      _(timeout).must_equal 20.0
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_ZIPKIN_ENDPOINT' => 'http://127.0.0.1:1234',
                                                'OTEL_EXPORTER_ZIPKIN_TRACES_HEADERS' => 'foo=bar,c=d',
                                                'OTEL_EXPORTER_ZIPKIN_TRACES_TIMEOUT' => '20') do
        OpenTelemetry::Exporter::Zipkin::Exporter.new(endpoint: 'http://localhost:4321',
                                                      headers: { 'x' => 'y' },
                                                      timeout: 12)
      end
      _(exp.instance_variable_get(:@headers)).must_equal('x' => 'y')
      _(exp.instance_variable_get(:@timeout)).must_equal 12.0
      _(exp.instance_variable_get(:@path)).must_equal ''
      http = exp.instance_variable_get(:@http)
      _(http.address).must_equal 'localhost'
      _(http.port).must_equal 4321
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::Zipkin::Exporter.new }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    end

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      resource = OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
      span_data = create_resource_span_data(name: 'collector-integration-test', resource: resource)
      result = exporter.export([span_data], timeout: nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    ensure
      WebMock.disable_net_connect!
    end

    it 'retries on timeout' do
      stub_request(:post, 'http://localhost:9411/api/v2/spans').to_timeout.then.to_return(status: 202)
      span_data = create_resource_span_data
      result = exporter.export([span_data], timeout: nil)
      _(result).must_equal(SUCCESS)
    end

    it 'returns TIMEOUT on timeout' do
      stub_request(:post, 'http://localhost:9411/api/v2/spans').to_return(status: 400)
      span_data = create_resource_span_data
      result = exporter.export([span_data], timeout: 0)
      _(result).must_equal(TIMEOUT)
    end

    it 'returns TIMEOUT on timeout after retrying' do
      stub_request(:post, 'http://localhost:9411/api/v2/spans').to_timeout.then.to_raise('this should not be reached')
      span_data = create_resource_span_data

      @retry_count = 0
      backoff_stubbed_call = lambda do |**_args|
        sleep(0.10)
        @retry_count += 1
        true
      end

      exporter.stub(:backoff?, backoff_stubbed_call) do
        _(exporter.export([span_data], timeout: 0.1)).must_equal(TIMEOUT)
      end
    ensure
      @retry_count = 0
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil, timeout: nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
    end

    it 'exports a span_data' do
      stub_post = stub_request(:post, DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT).to_return(status: 202)
      exporter = OpenTelemetry::Exporter::Zipkin::Exporter.new
      span_data = create_resource_span_data
      result = exporter.export([span_data], timeout: nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      assert_requested(stub_post)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT).to_return(status: 202)
      exporter = OpenTelemetry::Exporter::Zipkin::Exporter.new
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end
  end
end

def create_resource_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                              total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                              end_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp, attributes: nil, links: nil, events: nil, resource: nil,
                              instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('', 'v0.0.1'),
                              span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                              trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
  OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                          total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                          attributes, links, events, resource, instrumentation_scope, span_id, trace_id, trace_flags, tracestate)
end
