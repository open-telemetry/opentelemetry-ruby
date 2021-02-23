# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT = 'http://localhost:9411/api/v2/spans'

describe OpenTelemetry::Exporter::Zipkin::Exporter do
  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::Zipkin::CollectorExporter.new
      _(exp).wont_be_nil
    end

    # TODO
    
    it 'refuses an invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::Zipkin::Exporter.new(endpoint: 'not a url')
      end
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
      span_data = create_span_data(name: 'collector-integration-test', resource: resource)
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    ensure
      WebMock.disable_net_connect!
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
    end

    it 'exports a span_data' do
      stub_post = stub_request(:post, DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT).to_return(status: 200)
      exporter = OpenTelemetry::Exporter::Zipkin::Exporter.new
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      assert_requested(stub_post)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, DEFAULT_ZIPKIN_COLLECTOR_ENDPOINT).to_return(status: 200)
      exporter = OpenTelemetry::Exporter::Zipkin::Exporter.new
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    # TODO
  end
end
