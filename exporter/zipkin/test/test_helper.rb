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

OpenTelemetry.logger = Logger.new(File::NULL)

def create_span_data(status: nil, kind: nil, attributes: nil, total_recorded_attributes: 0, events: nil, total_recorded_events: 0, links: nil, total_recorded_links: 0, instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('vendorlib', '0.0.0'), trace_id: OpenTelemetry::Trace.generate_trace_id, trace_flags: OpenTelemetry::Trace::TraceFlags::DEFAULT, tracestate: nil)
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
    instrumentation_scope,
    OpenTelemetry::Trace.generate_span_id,
    trace_id,
    trace_flags,
    tracestate
  )
end

# Test helper for Zipkin Exporter
class InMemoryMetricsReporter
  include OpenTelemetry::SDK::Trace::Export::MetricsReporter
  attr_reader :counters, :records, :observes

  def initialize
    @counters = []
    @records = []
    @observes = []
  end

  def record_value(metric, value:, labels: {})
    @records << { metric: metric, value: value, labels: labels }
  end

  def observe_value(metric, value:, labels: {})
    @observes << { metric: metric, value: value, labels: labels }
  end

  def add_to_counter(metric, increment: 1, labels: {})
    @counters << { metric: metric, value: increment, labels: labels }
  end

  def empty?
    @counters.empty? && @records.empty? && @observes.empty?
  end
end
