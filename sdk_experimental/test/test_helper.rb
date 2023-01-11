# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require 'simplecov'
# # SimpleCov.start
# # SimpleCov.minimum_coverage 85

require 'opentelemetry-sdk-experimental'
require 'opentelemetry-test-helpers'
require 'minitest/autorun'
require 'pry'

def call_sampler(sampler, trace_id: nil, parent_context: OpenTelemetry::Context.current, links: nil, name: nil, kind: nil, attributes: nil)
  sampler.should_sample?(
    trace_id: trace_id || OpenTelemetry::Trace.generate_trace_id,
    parent_context: parent_context,
    links: links,
    name: name,
    kind: kind,
    attributes: attributes
  )
end

def trace_id(id)
  first = id >> 64
  second = id & 0xffff_ffff_ffff_ffff
  [first, second].pack('Q>Q>')
end

def parent_context(trace_id: nil, sampled: false, ot: nil) # rubocop:disable Naming/UncommunicativeMethodParamName
  span_context = OpenTelemetry::Trace::SpanContext.new(
    trace_id: trace_id || OpenTelemetry::Trace.generate_trace_id,
    trace_flags: sampled ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT,
    tracestate: ot.nil? ? OpenTelemetry::Trace::Tracestate::DEFAULT : OpenTelemetry::Trace::Tracestate.from_hash('ot' => ot)
  )
  span = OpenTelemetry::Trace.non_recording_span(span_context)
  OpenTelemetry::Trace.context_with_span(span, parent_context: OpenTelemetry::Context::ROOT)
end
