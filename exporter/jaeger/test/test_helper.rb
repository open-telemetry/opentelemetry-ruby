# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/exporter/jaeger'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new('/dev/null')

def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID, child_count: 0,
                     total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                     end_timestamp: Time.now, attributes: nil, links: nil, events: nil, resource: nil, instrumentation_library: nil,
                     span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                     trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, child_count, total_recorded_attributes,
                                          total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                          attributes, links, events, resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
end
