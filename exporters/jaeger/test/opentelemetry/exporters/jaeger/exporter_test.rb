# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporters::Jaeger::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  describe '#initialize' do
    it 'initializes' do
      exporter = OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: 6831)
      _(exporter).wont_be_nil
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: 6831) }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'returns FAILURE if an encoded span is too large' do
      exporter = OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: 6831, max_packet_size: 10)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(FAILURE)
    end

    it 'exports a span_data' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: socket.addr[1])
      span_data = create_span_data
      result = exporter.export([span_data])
      packet = socket.recvfrom(65_000)
      socket.close
      _(result).must_equal(SUCCESS)
      _(packet).wont_be_nil
    end

    it 'exports a span from a tracer' do
      socket = UDPSocket.new
      socket.bind('127.0.0.1', 0)
      exporter = OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: socket.addr[1])
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter, max_queue_size: 1, max_export_batch_size: 1)
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
      exporter = OpenTelemetry::Exporters::Jaeger::Exporter.new(service_name: 'test', host: '127.0.0.1', port: socket.addr[1], max_packet_size: 128)
      span_data = 3.times.map { create_span_data }
      result = exporter.export(span_data)
      packet1 = socket.recvfrom(65_000)
      packet2 = socket.recvfrom(65_000)
      socket.close
      _(result).must_equal(SUCCESS)
      _(packet1.size).must_be :<=, 128
      _(packet2.size).must_be :<=, 128
    end
  end

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID, child_count: 0,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                       end_timestamp: Time.now, attributes: nil, links: nil, events: nil, library_resource: nil, instrumentation_library: nil,
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, child_count, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, library_resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
  end
end
