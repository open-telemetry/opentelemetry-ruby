# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::GRPC::Exporter do
  SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE

  describe '#exporter' do
    it 'integrates with collector' do
      span_data = create_span_data
      exporter = OpenTelemetry::Exporter::OTLP::GRPC::Exporter.new(endpoint: 'http://localhost:4317')
      result = exporter.export([span_data])
      _(result).must_equal(SUCCESS)
    end
  end

  private

  def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                       total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                       end_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp, attributes: nil, links: nil, events: nil, resource: nil,
                       instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('', 'v0.0.1'),
                       span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                       trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
    resource ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
    OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                            total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                            attributes, links, events, resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
  end
end
