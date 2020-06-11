# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'
require 'faux_writer_helper'

# Give access to otherwise private members
module OpenTelemetry
  module Exporters
    module Datadog
      class Exporter
        attr_accessor :agent_writer
      end
    end
  end
end

describe OpenTelemetry::Exporters::Datadog::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILED_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_RETRYABLE
  FAILED_NOT_RETRYABLE = OpenTelemetry::SDK::Trace::Export::FAILED_NOT_RETRYABLE
  AGENT_URL = 'http://localhost:8126'

  let(:faux_writer) {
    FauxWriter.new(
      transport: Datadog::Transport::HTTP.default do |t|
        t.adapter :test
      end
    )
  }
  let(:exporter) { 
    OpenTelemetry::Exporters::Datadog::Exporter.new(service_name: 'test', agent_url: 'http://localhost:8126').tap do |exporter|
      exporter.agent_writer = faux_writer
    end
  }

  describe '#initialize' do
    it 'initializes' do
      _(exporter).wont_be_nil
    end
  end



  describe '#export' do
    before do
      OpenTelemetry.tracer_provider = OpenTelemetry::SDK::Trace::TracerProvider.new()
    end

    it 'returns FAILED_NOT_RETRYABLE when shutdown' do
      exporter.shutdown
      result = exporter.export(nil)
      _(result).must_equal(FAILED_NOT_RETRYABLE)
    end

    it 'exports a span_data' do
      span_data = create_span_data
      result = exporter.export([span_data])
      packet = exporter.agent_writer.spans
      _(result).must_equal(SUCCESS)
      _(packet).wont_be_nil
    end

    it 'exports a span from a tracer' do
      span_name = 'foo'
      processor = OpenTelemetry::Exporters::Datadog::DatadogSpanProcessor.new(exporter: exporter)
      OpenTelemetry.tracer_provider.add_span_processor(processor)
      OpenTelemetry.tracer_provider.tracer.start_root_span(span_name).finish
      OpenTelemetry.tracer_provider.shutdown
      packet = exporter.agent_writer.spans
      _(packet).wont_be_nil
      _(packet[0].name).must_equal(span_name)
    end
  end

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID, child_count: 0,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                       end_timestamp: Time.now, attributes: nil, links: nil, events: nil, library_resource: nil, instrumentation_library: nil,
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT)
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, child_count, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, library_resource, instrumentation_library, span_id, trace_id, trace_flags)

  end
end
