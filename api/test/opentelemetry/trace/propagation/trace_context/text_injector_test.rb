# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext::TextInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext

  let(:current_span_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.current_span_key
  end
  let(:extracted_span_context_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.extracted_span_context_key
  end
  let(:traceparent_key) { 'traceparent' }
  let(:tracestate_key) { 'tracestate' }
  let(:injector) do
    OpenTelemetry::Trace::Propagation::TraceContext::TextInjector.new(
      traceparent_key: traceparent_key,
      tracestate_key: tracestate_key
    )
  end
  let(:valid_traceparent_header) do
    '00-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:invalid_traceparent_header) do
    'FF-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:tracestate_header) { 'vendorname=opaquevalue' }
  let(:context) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b)
    span = Span.new(span_context: span_context)
    Context.empty.set_value(current_span_key, span)
  end
  let(:context_with_tracestate) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b,
                                   tracestate: tracestate_header)
    span = Span.new(span_context: span_context)
    Context.empty.set_value(current_span_key, span)
  end
  let(:context_without_current_span) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b,
                                   tracestate: tracestate_header)
    Context.empty.set_value(extracted_span_context_key, span_context)
  end

  describe '#inject' do
    it 'yields the carrier, key, and traceparent value from the context' do
      yielded = false
      injector.inject({}, context) do |c, k, v|
        _(c).must_equal({})
        _(k).must_equal(traceparent_key)
        _(v).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      _(yielded).must_equal(true)
    end

    it 'does not yield the tracestate from the context, if nil' do
      carrier = injector.inject({}, context) { |c, k, v| c[k] = v }
      _(carrier).wont_include(tracestate_key)
    end

    it 'yields the tracestate from the context, if provided' do
      carrier = injector.inject({}, context_with_tracestate) { |c, k, v| c[k] = v }
      _(carrier).must_include(tracestate_key)
    end

    it 'uses the default setter if one is not provided' do
      carrier = injector.inject({}, context_with_tracestate)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_key]).must_equal(tracestate_header)
    end

    it 'propagates remote context without current span' do
      carrier = injector.inject({}, context_with_tracestate)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_key]).must_equal(tracestate_header)
    end
  end
end
