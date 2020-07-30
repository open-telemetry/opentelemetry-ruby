# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporters::OTLP::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  describe '#initialize' do
    it 'initializes' do
      exporter = OpenTelemetry::Exporters::OTLP::Exporter.new(host: '127.0.0.1', port: 55681)
      _(exporter).wont_be_nil
    end
  end

  describe '#export' do
    let(:exporter) { OpenTelemetry::Exporters::OTLP::Exporter.new(host: '127.0.0.1', port: 55681) }

    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new(OpenTelemetry::SDK::Resources::Resource.telemetry_sdk)
    end

    it 'returns FAILURE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILURE)
    end

    it 'exports a span_data' do
      stub_request(:post, 'http://127.0.0.1:55681/v1/trace').to_return(status: 200)
      exporter = OpenTelemetry::Exporters::OTLP::Exporter.new(host: '127.0.0.1', port: 55681)
      span_data = create_span_data
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end

    it 'exports a span from a tracer' do
      stub_post = stub_request(:post, 'http://127.0.0.1:55681/v1/trace').to_return(status: 200)
      exporter = OpenTelemetry::Exporters::OTLP::Exporter.new(host: '127.0.0.1', port: 55681)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter, max_queue_size: 1, max_export_batch_size: 1)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span('foo').finish
      OpenTelemetry.tracer_provider.shutdown
      assert_requested(stub_post)
    end

    it 'translates all the things' do
      stub_request(:post, 'http://127.0.0.1:55681/v1/trace').to_return(status: 200)
      exporter = OpenTelemetry::Exporters::OTLP::Exporter.new(host: '127.0.0.1', port: 55681)
      processor = OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter: exporter)
      tracer = OpenTelemetry.tracer_provider.tracer('tracer', 'v0.0.1')
      other_tracer = OpenTelemetry.tracer_provider.tracer('other_tracer')
      trace_id = OpenTelemetry::Trace.generate_trace_id
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry::Trace.stub(:generate_trace_id, trace_id) do
        root = tracer.start_root_span('root', kind: :internal)
        tracer.in_span('child', with_parent: root, kind: :producer, links: [OpenTelemetry::Trace::Link.new(root.context, { 'attr' => 4 })]) do |span|
          span['b'] = true
          span['f'] = 1.1
          span['i'] = 2
          span['s'] = 'val'
          span.status = OpenTelemetry::Trace::Status.new(OpenTelemetry::Trace::Status::UNKNOWN_ERROR)
          tracer.in_span('client', kind: :client) do
            other_tracer.in_span('server', kind: :server) do
              span.add_event(name: 'event', attributes: { 'attr' => 42 })
            end
          end
          tracer.in_span('consumer', kind: :consumer) do
          end
        end
        root.finish
      end
      OpenTelemetry.tracer_provider.shutdown

      encoded_etsr = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
        Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
          resource_spans: [
            Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
              resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                attributes: [
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.name', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'opentelemetry')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.language', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: 'ruby')),
                  Opentelemetry::Proto::Common::V1::KeyValue.new(key: 'telemetry.sdk.version', value: Opentelemetry::Proto::Common::V1::AnyValue.new(string_value: "semver:#{OpenTelemetry::SDK::VERSION}")),
                ],
              ),
              instrumentation_library_spans: [
                Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                  instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                    name: 'tracer',
                    version: 'v0.0.1',
                  ),
                  spans: [],
                ),
                Opentelemetry::Proto::Trace::V1::InstrumentationLibrarySpans.new(
                  instrumentation_library: Opentelemetry::Proto::Common::V1::InstrumentationLibrary.new(
                    name: 'other_tracer',
                  ),
                  spans: [],
                )
              ]
            )
          ]
        )
      )

      assert_requested(:post, "http://127.0.0.1:55681/v1/trace")
      # assert_requested(:post, "http://127.0.0.1:55681/v1/trace") do |req|
      #   byebug
      #   req.body == encoded_etsr
      # end
    end
  end

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID, child_count: 0,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                       end_timestamp: Time.now, attributes: nil, links: nil, events: nil, library_resource: nil,
                       instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('', 'v0.0.1'),
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, child_count, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, library_resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
  end
end
