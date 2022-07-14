# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/jaeger'
require 'minitest/autorun'
require 'webmock/minitest'

def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                     total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp,
                     end_timestamp: OpenTelemetry::TestHelpers.exportable_timestamp, attributes: nil, links: nil, events: nil, resource: nil, instrumentation_scope: nil,
                     span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                     trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                          total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                          attributes, links, events, resource, instrumentation_scope, span_id, trace_id, trace_flags, tracestate)
end
