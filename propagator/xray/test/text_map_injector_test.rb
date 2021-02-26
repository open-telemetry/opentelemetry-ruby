# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::XRay::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags

  let(:injector) { OpenTelemetry::Propagator::XRay::TextMapInjector.new }

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      carrier = {}
      injector.inject(carrier, context)

      expected_xray = 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=1'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::DEFAULT
      )

      carrier = {}
      injector.inject(carrier, context)

      expected_xray = 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=0'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'injects debug flag when present' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        xray_debug: true
      )

      carrier = {}
      injector.inject(carrier, context)

      expected_xray = 'Root=1-80f198e-e56343ba864fe8b2a57d3eff7;Parent=e457b5a2e4d86bd1;Sampled=d'
      _(carrier['X-Amzn-Trace-Id']).must_equal(expected_xray)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )

      carrier = {}
      injector.inject(carrier, context)

      _(carrier.key?('X-Amzn-Trace-Id')).must_equal(false)
    end

    it 'no-ops if span id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )

      carrier = {}
      injector.inject(carrier, context)

      _(carrier.key?('X-Amzn-Trace-Id')).must_equal(false)
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: TraceFlags::DEFAULT,
                     xray_debug: false)
    context = OpenTelemetry::Trace.context_with_span(
      Span.new(
        span_context: SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
    context = OpenTelemetry::Propagator::XRay.context_with_debug(context) if xray_debug
    context
  end
end
