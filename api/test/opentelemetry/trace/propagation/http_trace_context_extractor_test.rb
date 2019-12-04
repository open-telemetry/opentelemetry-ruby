# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::HttpTraceContextExtractor do
  let(:span_context_key) do
    OpenTelemetry::Trace::Propagation::ContextKeys.span_context_key
  end
  let(:traceparent_header_key) { 'traceparent' }
  let(:tracestate_header_key) { 'tracestate' }
  let(:extractor) do
    OpenTelemetry::Trace::Propagation::HttpTraceContextExtractor.new(
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
  let(:carrier) do
    {
      traceparent_header_key => valid_traceparent_header,
      tracestate_header_key => tracestate_header
    }
  end
  let(:context) { Context.empty }

  describe '#extract' do
    it 'yields the carrier and the header key' do
      yielded_keys = []
      extractor.extract(context, carrier) do |c, key|
        _(c).must_equal(carrier)
        yielded_keys << key
        c[key]
      end
      _(yielded_keys.sort).must_equal([traceparent_header_key, tracestate_header_key])
    end

    it 'returns a remote SpanContext with fields from the traceparent and tracestate headers' do
      ctx = extractor.extract(context, carrier) { |c, k| c[k] }
      span_context = ctx[span_context_key]
      _(span_context).must_be :remote?
      _(span_context.trace_id).must_equal('000000000000000000000000000000aa')
      _(span_context.span_id).must_equal('00000000000000ea')
      _(span_context.trace_flags).must_be :sampled?
      _(span_context.tracestate).must_equal('vendorname=opaquevalue')
    end

    it 'uses a default getter if one is not provided' do
      ctx = extractor.extract(context, carrier)
      span_context = ctx[span_context_key]
      _(span_context).must_be :remote?
      _(span_context.trace_id).must_equal('000000000000000000000000000000aa')
      _(span_context.span_id).must_equal('00000000000000ea')
      _(span_context.trace_flags).must_be :sampled?
      _(span_context.tracestate).must_equal('vendorname=opaquevalue')
    end

    it 'returns a valid non-remote SpanContext on error' do
      ctx = extractor.extract(context, {}) { invalid_traceparent_header }
      span_context = ctx[span_context_key]
      _(span_context).wont_be :remote?
      _(span_context).must_be :valid?
    end
  end
end
