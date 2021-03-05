# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::B3::Multi::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags

  let(:injector) { OpenTelemetry::Propagator::B3::Multi::TextMapInjector.new }
  let(:trace_id_key) { 'X-B3-TraceId' }
  let(:span_id_key) { 'X-B3-SpanId' }
  let(:parent_span_id_key) { 'X-B3-ParentSpanId' }
  let(:sampled_key) { 'X-B3-Sampled' }
  let(:flags_key) { 'X-B3-Flags' }
  let(:all_keys) { [trace_id_key, span_id_key, parent_span_id_key, sampled_key, flags_key] }

  describe '#inject' do
    it 'injects context with sampled trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::SAMPLED
      )

      carrier = {}
      updated_carrier = injector.inject(carrier, context)

      _(updated_carrier).must_be_same_as(updated_carrier)
      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[sampled_key]).must_equal('1')
      _(carrier.key?(flags_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'injects context with default trace flags' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        trace_flags: TraceFlags::DEFAULT
      )

      carrier = {}
      updated_carrier = injector.inject(carrier, context)

      _(updated_carrier).must_be_same_as(updated_carrier)
      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[sampled_key]).must_equal('0')
      _(carrier.key?(flags_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'injects debug flag when present' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: 'e457b5a2e4d86bd1',
        b3_debug: true
      )

      carrier = {}
      updated_carrier = injector.inject(carrier, context)

      _(updated_carrier).must_be_same_as(updated_carrier)
      _(carrier[trace_id_key]).must_equal('80f198ee56343ba864fe8b2a57d3eff7')
      _(carrier[span_id_key]).must_equal('e457b5a2e4d86bd1')
      _(carrier[flags_key]).must_equal('1')
      _(carrier.key?(sampled_key)).must_equal(false)
      _(carrier.key?(parent_span_id_key)).must_equal(false)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '0' * 32,
        span_id: 'e457b5a2e4d86bd1'
      )

      carrier = {}

      unchanged_carrier = injector.inject(carrier, context)

      _(unchanged_carrier).must_be_same_as(carrier)
      _(unchanged_carrier).must_be(:empty?)
    end

    it 'no-ops if trace id invalid' do
      context = create_context(
        trace_id: '80f198ee56343ba864fe8b2a57d3eff7',
        span_id: '0' * 16
      )

      carrier = {}

      unchanged_carrier = injector.inject(carrier, context)

      _(unchanged_carrier).must_be_same_as(carrier)
      _(unchanged_carrier).must_be(:empty?)
    end
  end

  def create_context(trace_id:,
                     span_id:,
                     trace_flags: TraceFlags::DEFAULT,
                     b3_debug: false)
    context = OpenTelemetry::Trace.context_with_span(
      Span.new(
        span_context: SpanContext.new(
          trace_id: Array(trace_id).pack('H*'),
          span_id: Array(span_id).pack('H*'),
          trace_flags: trace_flags
        )
      )
    )
    context = OpenTelemetry::Propagator::B3.context_with_debug(context) if b3_debug
    context
  end
end
