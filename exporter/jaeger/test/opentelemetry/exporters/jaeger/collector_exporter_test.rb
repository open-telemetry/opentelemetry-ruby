# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Jaeger::CollectorExporter do
  describe '#initialize' do
    it 'initializes with defaults' do
      exp = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      _(exp).wont_be_nil

      client = exp.instance_variable_get(:@client)
      protocol = client.instance_variable_get(:@oprot)
      transport = protocol.trans
      headers = transport.instance_variable_get(:@headers)
      url = transport.instance_variable_get(:@url)
      _(headers).wont_include 'Authorization'
      _(url.host).must_equal 'localhost'
      _(url.port).must_equal 14_268
    end

    it 'refuses an invalid endpoint' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(endpoint: 'not a url')
      end
    end

    it 'refuses non-nil username with nil password and vice versa' do
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(username: 'foo')
      end
      assert_raises ArgumentError do
        OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(password: 'bar')
      end
    end

    it 'accepts non-nil username and password' do
      exp = OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(username: 'foo', password: 'bar')
      _(exp).wont_be_nil

      client = exp.instance_variable_get(:@client)
      protocol = client.instance_variable_get(:@oprot)
      transport = protocol.trans
      headers = transport.instance_variable_get(:@headers)
      _(headers).must_include :Authorization
      _(headers[:Authorization]).must_equal "Basic #{Base64.strict_encode64('foo:bar')}"
    end

    it 'sets parameters from the environment' do
      exp = with_env('OTEL_EXPORTER_JAEGER_ENDPOINT' => 'http://127.0.0.1:1234',
                     'OTEL_EXPORTER_JAEGER_USER' => 'foo',
                     'OTEL_EXPORTER_JAEGER_PASSWORD' => 'bar') do
        OpenTelemetry::Exporter::Jaeger::CollectorExporter.new
      end
      client = exp.instance_variable_get(:@client)
      protocol = client.instance_variable_get(:@oprot)
      transport = protocol.trans
      headers = transport.instance_variable_get(:@headers)
      url = transport.instance_variable_get(:@url)
      _(headers).must_include :Authorization
      _(headers[:Authorization]).must_equal "Basic #{Base64.strict_encode64('foo:bar')}"
      _(url.host).must_equal '127.0.0.1'
      _(url.port).must_equal 1_234
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = with_env('OTEL_EXPORTER_JAEGER_ENDPOINT' => 'http://127.0.0.1:1234',
                     'OTEL_EXPORTER_JAEGER_USER' => 'foo',
                     'OTEL_EXPORTER_JAEGER_PASSWORD' => 'bar') do
        OpenTelemetry::Exporter::Jaeger::CollectorExporter.new(endpoint: 'http://192.168.0.1:4321',
                                                               username: 'bar',
                                                               password: 'baz')
      end
      client = exp.instance_variable_get(:@client)
      protocol = client.instance_variable_get(:@oprot)
      transport = protocol.trans
      headers = transport.instance_variable_get(:@headers)
      url = transport.instance_variable_get(:@url)
      _(headers).must_include :Authorization
      _(headers[:Authorization]).must_equal "Basic #{Base64.strict_encode64('bar:baz')}"
      _(url.host).must_equal '192.168.0.1'
      _(url.port).must_equal 4_321
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
