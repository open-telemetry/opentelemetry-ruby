# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TraceContext::TextMapInjector do
  Span = OpenTelemetry::Trace::Span
  SpanReference = OpenTelemetry::Trace::SpanReference

  let(:traceparent_key) { 'traceparent' }
  let(:tracestate_key) { 'tracestate' }
  let(:injector) do
    OpenTelemetry::Trace::Propagation::TraceContext::TextMapInjector.new(
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
    span_reference = SpanReference.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b)
    span = Span.new(span_reference: span_reference)
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
  end
  let(:context_with_tracestate) do
    span_reference = SpanReference.new(trace_id: ("\xff" * 16).b, span_id: ("\x11" * 8).b,
                                       tracestate: tracestate_header)
    span = Span.new(span_reference: span_reference)
    OpenTelemetry::Trace.context_with_span(span, parent_context: Context.empty)
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
