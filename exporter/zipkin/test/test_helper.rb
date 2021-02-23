# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/exporter/zipkin'
require 'minitest/autorun'
require 'webmock/minitest'

def create_span_data(name: '', kind: nil, status: nil, parent_span_id: OpenTelemetry::Trace::INVALID_SPAN_ID,
                     total_recorded_attributes: 0, total_recorded_events: 0, total_recorded_links: 0, start_timestamp: Time.now,
                     end_timestamp: Time.now, attributes: nil, links: nil, events: nil, resource: nil, instrumentation_library: nil,
                     span_id: OpenTelemetry::Trace.generate_span_id, trace_id: OpenTelemetry::Trace.generate_trace_id,
                     trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
  OpenTelemetry::SDK::Trace::SpanData.new(name, kind, status, parent_span_id, total_recorded_attributes,
                                          total_recorded_events, total_recorded_links, start_timestamp, end_timestamp,
                                          attributes, links, events, resource, instrumentation_library, span_id, trace_id, trace_flags, tracestate)
end

def with_env(new_env)
  env_to_reset = ENV.select { |k, _| new_env.key?(k) }
  keys_to_delete = new_env.keys - ENV.keys
  new_env.each_pair { |k, v| ENV[k] = v }
  yield
ensure
  env_to_reset.each_pair { |k, v| ENV[k] = v }
  keys_to_delete.each { |k| ENV.delete(k) }
end
