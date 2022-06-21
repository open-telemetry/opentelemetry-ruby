# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/zipkin'
require 'minitest/autorun'
require 'webmock/minitest'

def create_span_data(status: nil, kind: nil, attributes: nil, total_recorded_attributes: 0, events: nil, total_recorded_events: 0, links: nil, total_recorded_links: 0, instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('vendorlib', '0.0.0'), trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  OpenTelemetry::SDK::Trace::SpanData.new(
    '',
    kind,
    status,
    OpenTelemetry::Trace::INVALID_SPAN_ID,
    total_recorded_attributes,
    total_recorded_events,
    total_recorded_links,
    OpenTelemetry::TestHelpers.exportable_timestamp,
    OpenTelemetry::TestHelpers.exportable_timestamp,
    attributes,
    links,
    events,
    nil,
    instrumentation_library,
    OpenTelemetry::Trace.generate_span_id,
    trace_id,
    trace_flags,
    tracestate
  )
end
