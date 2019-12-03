# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Propagation::TextFormat do
  let(:traceparent_header_key) { 'traceparent' }
  let(:tracestate_header_key) { 'tracestate' }
  let(:formatter) do
    OpenTelemetry::Trace::Propagation::TextFormat.new(
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

  describe '#extract' do
    let(:carrier) do
      {
        traceparent_header_key => valid_traceparent_header,
        tracestate_header_key => tracestate_header
      }
    end

    it 'yields the carrier and the header key' do
      yielded_keys = []
      formatter.extract(carrier) do |c, key|
        _(c).must_equal(carrier)
        yielded_keys << key
        c[key]
      end
      _(yielded_keys.sort).must_equal([traceparent_header_key, tracestate_header_key])
    end

    it 'returns a remote SpanContext with fields from the traceparent and tracestate headers' do
      context = formatter.extract(carrier) { |c, k| c[k] }
      _(context).must_be :remote?
      _(context.trace_id).must_equal('000000000000000000000000000000aa')
      _(context.span_id).must_equal('00000000000000ea')
      _(context.trace_flags).must_be :sampled?
      _(context.tracestate).must_equal('vendorname=opaquevalue')
    end

    it 'uses a default getter if one is not provided' do
      context = formatter.extract(carrier)
      _(context).must_be :remote?
      _(context.trace_id).must_equal('000000000000000000000000000000aa')
      _(context.span_id).must_equal('00000000000000ea')
      _(context.trace_flags).must_be :sampled?
      _(context.tracestate).must_equal('vendorname=opaquevalue')
    end

    it 'returns a valid non-remote SpanContext on error' do
      context = formatter.extract({}) { invalid_traceparent_header }
      _(context).wont_be :remote?
      _(context).must_be :valid?
    end
  end

  describe '#inject' do
    let(:span_context) do
      OpenTelemetry::Trace::SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
    end

    let(:span_context_with_tracestate) do
      OpenTelemetry::Trace::SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16, tracestate: tracestate_header)
    end

    it 'yields the carrier, key, and traceparent value from the context' do
      carrier = {}
      yielded = false
      formatter.inject(span_context, carrier) do |c, k, v|
        _(c).must_equal(carrier)
        _(k).must_equal(traceparent_header_key)
        _(v).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      _(yielded).must_equal(true)
    end

    it 'does not yield the tracestate from the context, if nil' do
      carrier = {}
      formatter.inject(span_context, carrier) { |c, k, v| c[k] = v }
      _(carrier).wont_include(tracestate_header_key)
    end

    it 'yields the tracestate from the context, if provided' do
      carrier = {}
      formatter.inject(span_context_with_tracestate, carrier) { |c, k, v| c[k] = v }
      _(carrier).must_include(tracestate_header_key)
    end

    it 'uses the default setter if one is not provided' do
      carrier = {}
      formatter.inject(span_context_with_tracestate, carrier)
      _(carrier[traceparent_header_key]).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
      _(carrier[tracestate_header_key]).must_equal(tracestate_header)
    end
  end

  describe '#fields' do
    it 'returns an array with the W3C traceparent header' do
      _(formatter.fields.sort).must_equal([traceparent_header_key, tracestate_header_key])
    end
  end
end
