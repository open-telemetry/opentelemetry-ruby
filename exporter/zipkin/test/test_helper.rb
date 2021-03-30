# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/exporter/zipkin'
require 'opentelemetry/common/test_helpers'
require 'minitest/autorun'
require 'webmock/minitest'

def create_span_data(status: nil, kind: nil, attributes: nil, events: nil, links: nil, instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('vendorlib', '0.0.0'), trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  OpenTelemetry::SDK::Trace::SpanData.new(
    '',
    kind,
    status,
    OpenTelemetry::Trace::INVALID_SPAN_ID,
    0,
    0,
    0,
    Time.now,
    Time.now,
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
