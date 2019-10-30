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
  let(:valid_header) do
    '00-000000000000000000000000000000AA-00000000000000ea-01'
  end
  let(:invalid_header) do
    'FF-000000000000000000000000000000AA-00000000000000ea-01'
  end

  describe '#extract' do
    it 'yields the carrier and the header key' do
      carrier = {}
      yielded = false
      formatter.extract(carrier) do |c, key|
        _(c).must_equal(carrier)
        _(key).must_equal('traceparent')
        yielded = true
        valid_header
      end
      _(yielded).must_equal(true)
    end

    it 'returns a remote SpanContext with fields from the traceparent header' do
      context = formatter.extract({}) { valid_header }
      _(context).must_be :remote?
      _(context.trace_id).must_equal('000000000000000000000000000000aa')
      _(context.span_id).must_equal('00000000000000ea')
      _(context.trace_flags).must_be :sampled?
    end

    it 'returns a valid non-remote SpanContext on error' do
      context = formatter.extract({}) { invalid_header }
      _(context).wont_be :remote?
      _(context).must_be :valid?
    end
  end

  describe '#inject' do
    it 'yields the carrier, key, and traceparent value from the context' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      carrier = {}
      yielded = false
      formatter.inject(context, carrier) do |c, k, v|
        _(c).must_equal(carrier)
        _(k).must_equal('traceparent')
        _(v).must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      _(yielded).must_equal(true)
    end
  end

  describe '#fields' do
    it 'returns an array with the W3C traceparent header' do
      _(formatter.fields).must_equal(['traceparent'])
    end
  end
end
