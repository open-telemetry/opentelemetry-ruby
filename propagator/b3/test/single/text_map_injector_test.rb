# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Single::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags

  let(:injector) { OpenTelemetry::Propagator::B3::Single::TextMapInjector.new }
  let(:extractor) { OpenTelemetry::Propagator::B3::Single::TextMapExtractor.new }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer }

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      carrier = {}
      injector.inject(carrier, context)

      expected_b3 = '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-1'
      _(carrier['b3']).must_equal(expected_b3)
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::DEFAULT
      )

      carrier = {}
      injector.inject(carrier, context)

      expected_b3 = '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-0'
      _(carrier['b3']).must_equal(expected_b3)
    end

    it 'injects debug flag when present' do
      expected_b3 = '80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-d'
      context = extractor.extract({ 'b3' => expected_b3 }, OpenTelemetry::Context.empty)

      carrier = {}
      injector.inject(carrier, context)

      _(carrier['b3']).must_equal(expected_b3)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )

      carrier = {}
      injector.inject(carrier, context)

      _(carrier.key?('b3')).must_equal(false)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )

      carrier = {}
      injector.inject(carrier, context)

      _(carrier.key?('b3')).must_equal(false)
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: TraceFlags::DEFAULT,
                     b3_debug: false)

    tracer.context_with_span(
      Span.new(
        span_context: SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
  end
end
