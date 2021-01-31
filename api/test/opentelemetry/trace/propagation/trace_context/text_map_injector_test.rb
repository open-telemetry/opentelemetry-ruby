# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanContext = OpenTelemetry::Trace::SpanContext

  let(:traceparent_key) { 'traceparent' }
  let(:tracestate_key) { 'tracestate' }
  let(:injector) do
    OpenTelemetry::Trace::Propagation::TraceContext::TextMapInjector.new
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
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
  end
  let(:context_with_tracestate) do
    span_context = SpanContext.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b,
                                   tracestate: tracestate_header)
    span = Span.new(span_context: span_context)
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
  end

  describe '#inject' do
    it 'writes traceparent into the carrier' do
      carrier = {}
      injector.inject(carrier, context)
      _(carrier[traceparent_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
    end

    it 'does not write the tracestate into carrier, if nil' do
      carrier = injector.inject({}, context)
      _(carrier).wont_include(tracestate_key)
    end

    it 'writes the tracestate into the context, if provided' do
      carrier = injector.inject({}, context_with_tracestate)
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
