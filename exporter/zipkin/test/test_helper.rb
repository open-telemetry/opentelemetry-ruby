# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
SimpleCov.start

require 'opentelemetry/exporter/zipkin'
require 'minitest/autorun'
require 'webmock/minitest'

def with_env(new_env)
  env_to_reset = ENV.select { |k, _| new_env.key?(k) }
  keys_to_delete = new_env.keys - ENV.keys
  new_env.each_pair { |k, v| ENV[k] = v }
  yield
ensure
  env_to_reset.each_pair { |k, v| ENV[k] = v }
  keys_to_delete.each { |k| ENV.delete(k) }
end

def create_span_data(status: nil, kind: nil, attributes: nil, events: nil, links: nil, instrumentation_library: nil, trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
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
