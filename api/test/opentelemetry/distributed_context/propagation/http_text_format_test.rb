# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat do
  SpanContext = OpenTelemetry::Trace::SpanContext
  HTTPTextFormat =
    OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat

  let(:formatter) { HTTPTextFormat.new }
  let(:valid_traceparent_header) do
    '00-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:invalid_traceparent_header) do
    'FF-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:tracestate_header) { 'vendorname=opaquevalue' }

  describe '#extract' do
    it 'yields the carrier and the header key' do
      carrier = {
        'traceparent' => valid_traceparent_header,
        'tracestate' => tracestate_header
      }
      yielded_keys = []
      formatter.extract(carrier) do |c, key|
        _(c).must_equal(carrier)
        yielded_keys << key
        c[key]
      end
      _(yielded_keys.sort).must_equal(['traceparent', 'tracestate'])
    end

    it 'returns a remote SpanContext with fields from the traceparent and tracestate headers' do
      carrier = {
        'traceparent' => valid_traceparent_header,
        'tracestate' => tracestate_header
      }
      context = formatter.extract(carrier) { |c, k| c[k] }
      _(context).must_be :remote?
      _(context.trace_id).must_equal('000000000000000000000000000000aa')
      _(context.span_id).must_equal('00000000000000ea')
      _(context.trace_flags).must_be :sampled?
      _(context.tracestate).must_equal('vendorname=opaquevalue')
    end

    it 'returns a valid non-remote SpanContext on error' do
      context = formatter.extract({}) { invalid_header }
      context.wont_be :remote?
      context.must_be :valid?
    end
  end

  describe '#inject' do
    it 'yields the carrier, key, and traceparent value from the context' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      carrier = {}
      yielded = false
      formatter.inject(context, carrier) do |c, k, v|
        c.must_equal(carrier)
        k.must_equal('traceparent')
        v.must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      yielded.must_equal(true)
    end

    it 'does not yield the tracestate from the context, if nil' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16, tracestate: nil)
      carrier = {}
      formatter.inject(context, carrier) { |c, k, v| c[k] = v }
      _(carrier).wont_include('tracestate')
    end

    it 'yields the tracestate from the context, if provided' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16, tracestate: tracestate_header)
      carrier = {}
      formatter.inject(context, carrier) { |c, k, v| c[k] = v }
      _(carrier).must_include('tracestate')
    end
  end

  describe '#fields' do
    it 'returns an array with the W3C traceparent header' do
      _(formatter.fields.sort).must_equal(['traceparent', 'tracestate'])
    end
  end
end
