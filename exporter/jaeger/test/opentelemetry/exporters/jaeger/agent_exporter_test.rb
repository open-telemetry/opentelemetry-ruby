# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::Jaeger::AgentExporter do
  describe '#initialize' do
    it 'initializes' do
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: 6831)
      _(exporter).wont_be_nil
    end

    it 'sets parameters from the environment' do
      exp = with_env('OTEL_EXPORTER_JAEGER_TIMEOUT' => '42') do
        OpenTelemetry::Exporter::Jaeger::AgentExporter.new
      end
      _(exp.instance_variable_get(:@timeout)).must_equal 42.0
    end

    it 'prefers explicit parameters rather than the environment' do
      exp = with_env('OTEL_EXPORTER_JAEGER_TIMEOUT' => '42') do
        OpenTelemetry::Exporter::Jaeger::AgentExporter.new(timeout: 60)
      end
      _(exp.instance_variable_get(:@timeout)).must_equal 60.0
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: 6831) }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    end

    it 'integrates with agent' do
      skip unless ENV['TRACING_INTEGRATION_TEST']
      resource = OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
      span_data = create_span_data(name: 'agent-integration-test', resource: resource)
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
    end

    it 'returns FAILURE if an encoded span is too large' do
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: 6831, max_packet_size: 10)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::FAILURE)
    end

    it 'exports a span_data' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: socket.addr[1])
      span_data = create_span_data
      result = exporter.export([span_data])
      packet = socket.recvfrom(65_000)
      socket.close
      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      _(packet).wont_be_nil
    end

    it 'exports a span from a tracer' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: socket.addr[1])
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      packet = socket.recvfrom(65_000)
      socket.close
      _(packet).wont_be_nil
    end

    it 'limits packet sizes' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: socket.addr[1], max_packet_size: 128)
      span_data = 3.times.map { create_span_data }
      result = exporter.export(span_data)
      packet1 = socket.recvfrom(65_000)
      packet2 = socket.recvfrom(65_000)
      socket.close

      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      _(packet1.size).must_be :<=, 128
      _(packet2.size).must_be :<=, 128
    end

    it 'batches per resource' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporter::Jaeger::AgentExporter.new(host: '127.0.0.1', port: socket.addr[1], max_packet_size: 128)

      span_data1 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k1' => 'v1'))
      span_data2 = create_span_data(resource: OpenTelemetry::SDK::Resources::Resource.create('k2' => 'v2'))

      result = exporter.export([span_data1, span_data2])
      packet1 = socket.recvfrom(65_000)
      packet2 = socket.recvfrom(65_000)
      socket.close

      _(result).must_equal(OpenTelemetry::SDK::Trace::Export::SUCCESS)
      _(packet1).wont_be_nil
      _(packet2).wont_be_nil
    end
  end
end
