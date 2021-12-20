# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext

  let(:traceparent_key) { 'traceparent' }
  let(:tracestate_key) { 'tracestate' }
  let(:propagator) do
    OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new
  end
  let(:valid_traceparent_header) do
    '00-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:invalid_traceparent_header) do
    'FF-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:tracestate_header) { 'vendorname=opaquevalue' }
  let(:tracestate) { OpenTelemetry::Trace::Tracestate.from_hash('vendorname' => 'opaquevalue') }
  let(:carrier) do
    {
      traceparent_key => valid_traceparent_header,
      tracestate_key => tracestate_header
    }
  end
  let(:context) { Context.empty }
  let(:context_with_tracestate) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b,
                                   tracestate: tracestate_header)
    span = OpenTelemetry::Trace.non_recording_span(span_context)
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
  end
  let(:context_without_tracestate) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b)
    span = OpenTelemetry::Trace.non_recording_span(span_context)
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
  end

  describe '#extract' do
    it 'returns a remote SpanContext with fields from the traceparent and tracestate headers' do
      ctx = propagator.extract(carrier, context: context) { |c, k| c[k] }
      span_context = OpenTelemetry::Trace.current_span(ctx).context
      _(span_context).must_be :remote?
      _(span_context.trace_id).must_equal(("\0" * 15 + "\xaa").b)
      _(span_context.span_id).must_equal(("\0" * 7 + "\xea").b)
      _(span_context.trace_flags).must_be :sampled?
      _(span_context.tracestate).must_equal(tracestate)
    end

    it 'uses a default getter if one is not provided' do
      ctx = propagator.extract(carrier, context: context)
      span_context = OpenTelemetry::Trace.current_span(ctx).context
      _(span_context).must_be :remote?
      _(span_context.trace_id).must_equal(("\0" * 15 + "\xaa").b)
      _(span_context.span_id).must_equal(("\0" * 7 + "\xea").b)
      _(span_context.trace_flags).must_be :sampled?
      _(span_context.tracestate).must_equal(tracestate)
    end

    it 'returns original context on error' do
      ctx = propagator.extract({}, context: context) { invalid_traceparent_header }
      _(ctx).must_equal(context)
    end

    it 'should apply current span on argument context' do
      key = Context.create_key('key1')
      ctx = Context::ROOT.set_value(key, 'value1')
      extracted_ctx = propagator.extract(carrier, context: ctx) { |c, k| c[k] }

      _(extracted_ctx.value(key)).must_equal('value1')
    end
  end

  describe '#inject' do
    it 'writes traceparent into the carrier' do
      carrier = {}
      propagator.inject(carrier, context: context_without_tracestate)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
    end

    it 'does not write the tracestate into carrier, if nil' do
      carrier = {}
      propagator.inject(carrier, context: context_without_tracestate)
      _(carrier).wont_include(tracestate_key)
    end

    it 'writes the tracestate into the context, if provided' do
      carrier = {}
      propagator.inject(carrier, context: context_with_tracestate)
      _(carrier).must_include(tracestate_key)
    end

    it 'uses the default setter if one is not provided' do
      carrier = {}
      propagator.inject(carrier, context: context_with_tracestate)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_key]).must_equal(tracestate_header)
    end

    it 'propagates remote context without current span' do
      carrier = {}
      propagator.inject(carrier, context: context_with_tracestate)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_key]).must_equal(tracestate_header)
    end
  end
end
