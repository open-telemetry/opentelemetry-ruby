# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Jaeger::CollectorExporter do
  describe '#initialize' do
    it 'initializes' do
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      _(exporter).wont_be_nil
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::Jaeger::CollectorExporter.new }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    end

    it 'integrates with collector' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      WebMock.disable_net_connect!(allow: 'localhost')
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
    end

    it 'exports a span_data' do
      stub_post = stub_request(:post, 'http://localhost:14268').to_return { |request| ok_result(request.body) }
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      assert_requested(stub_post)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, 'http://localhost:14268').to_return { |request| ok_result(request.body) }
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      stub_post = stub_request(:post, 'http://localhost:14268').to_return { |request| ok_result(request.body) }
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new

      span_data1 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      span_data2 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([span_data1, span_data2])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      assert_requested(stub_post)
    end
  end

  module Handler
    def self.submitBatches(batches) # rubocop:disable Naming/MethodName
      batches.map { OpenTelemetry::Exporter::Jaeger::Thrift::BatchSubmitResponse.new('ok' => true) }
    end
  end

  def ok_result(request_body)
    transport = ::Thrift::MemoryBufferTransport.new(request_body)
    protocol = ::Thrift::BinaryProtocol.new(transport)
    processor = OpenTelemetry::Exporter::Jaeger::Thrift::Collector::Processor.new(Handler)
    processor.process(protocol, protocol)
    { body: transport.read(transport.available), status: 200 }
  end
end
