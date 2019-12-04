# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::HttpTraceContextInjector do
  SpanContext = OpenTelemetry::Trace::SpanContext
  let(:span_context_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.span_context_key
  end
  let(:traceparent_header_key) { 'traceparent' }
  let(:tracestate_header_key) { 'tracestate' }
  let(:injector) do
    OpenTelemetry::Trace::Propagation::HttpTraceContextInjector.new(
      traceparent_header_key: traceparent_header_key,
      tracestate_header_key: tracestate_header_key
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
    span_context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
    Context.empty.set_value(span_context_key, span_context)
  end
  let(:context_with_tracestate) do
    span_context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16,
                                   tracestate: tracestate_header)
    Context.empty.set_value(span_context_key, span_context)
  end

  describe '#inject' do
    it 'yields the carrier, key, and traceparent value from the context' do
      yielded = false
      injector.inject(context, {}) do |c, k, v|
        _(c).must_equal({})
        _(k).must_equal(traceparent_header_key)
        _(v).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      _(yielded).must_equal(true)
    end

    it 'does not yield the tracestate from the context, if nil' do
      carrier = injector.inject(context, {}) { |c, k, v| c[k] = v }
      _(carrier).wont_include(tracestate_header_key)
    end

    it 'yields the tracestate from the context, if provided' do
      carrier = injector.inject(context_with_tracestate, {}) { |c, k, v| c[k] = v }
      _(carrier).must_include(tracestate_header_key)
    end

    it 'uses the default setter if one is not provided' do
      carrier = injector.inject(context_with_tracestate, {})
      _(carrier[traceparent_header_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_header_key]).must_equal(tracestate_header)
    end
  end
end
