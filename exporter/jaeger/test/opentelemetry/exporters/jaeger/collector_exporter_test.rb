# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Jaeger::CollectorExporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

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

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'exports a span_data' do
      stub_post = stub_request(:post, 'http://localhost:14250').to_return { |request| ok_result(request) }
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, 'http://localhost:14250').to_return { |request| ok_result(request) }
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    it 'batches per resource' do
      stub_post = stub_request(:post, 'http://localhost:14250').to_return(body: result([true, true]), status: 200)
      exporter = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new

      span_data1 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      span_data2 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([span_data1, span_data2])
      _(result).must_equal(SUCCESS)
      assert_requested(stub_post)
    end
  end

  def ok_result(request)
    # TODO mock out the Thrift handler and wrap it in a Processor, etc.
    r = OpenTelemetry::Exporter::Jaeger::Thrift::Collector::SubmitBatches_result.new
    r.success = ok_array.map { |ok| OpenTelemetry::Exporter::Jaeger::Thrift::BatchSubmitResponse.new('ok' => ok) }
    transport = ::Thrift::MemoryBufferTransport.new
    protocol = ::Thrift::BinaryProtocol.new(transport)
    r.write(protocol)
    transport.read(transport.available)
  end
end
