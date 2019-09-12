# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::DistributedContext::Propagation::TraceParent do
  TraceParent = OpenTelemetry::DistributedContext::Propagation::TraceParent
  Trace = OpenTelemetry::Trace
  let(:good) do
    flags = Trace::TraceFlags.from_byte(1)
    TraceParent.from_context(Trace::SpanContext.new(trace_flags: flags))
  end

  describe '.to_s' do
    it 'formats it correctly' do
      expected = "00-#{good.trace_id}-#{good.span_id}-01"
      good.to_s.must_equal(expected)
    end

    it 'should be lowercase' do
      good.to_s.must_equal good.to_s.downcase
    end
  end

  it 'should make a traceparent from a span context' do
    sp = OpenTelemetry::Trace::SpanContext.new
    tp = TraceParent.from_context(sp)

    sp.trace_id.must_equal tp.trace_id
    sp.span_id.must_equal  tp.span_id
    sp.trace_flags.must_equal tp.flags
  end

  describe 'parsing' do
    it 'must accept mixed case' do
      value = '00-000000000000000000000000000000AA-00000000000000ea-01'
      tp = TraceParent.from_string(value)
      tp.to_s.must_equal value.downcase
    end

    it 'must not accept a version of 255' do
      value = 'FF-000000000000000000000000000000AA-00000000000000ea-01'

      proc {
        TraceParent.from_string(value)
      }.must_raise TraceParent::InvalidVersionError
    end

    it 'must not accept a trace-id of all zeros' do
      value = '00-00000000000000000000000000000000-00000000000000ea-01'

      proc {
        TraceParent.from_string(value)
      }.must_raise TraceParent::InvalidTraceIDError
    end

    it 'must not accept a span-id of all zeros' do
      value = '00-0000000000000000000000000000000a-0000000000000000-01'

      proc {
        TraceParent.from_string(value)
      }.must_raise TraceParent::InvalidSpanIDError
    end

    it 'must parse a higher version header according to the w3c standard' do
      value = '10-0000000000000000000000000000000a-000000000000000a-ff'
      tp = TraceParent.from_string(value)
      expected = '00-0000000000000000000000000000000a-000000000000000a-01'
      tp.to_s.must_equal(expected)

      value = '7f-0000000000000000000000000000000a-000000000000000a-04'
      tp = TraceParent.from_string(value)
      expected = '00-0000000000000000000000000000000a-000000000000000a-00'
      tp.to_s.must_equal(expected)
    end

    it 'must ignore flags it doesnt know (use the mask)' do
      value = '00-0000000000000000000000000000000a-000000000000000a-ff'
      assert TraceParent.from_string(value).sampled?
      value = '00-0000000000000000000000000000000a-000000000000000a-04'
      assert !TraceParent.from_string(value).sampled?
    end

    it 'must have a trace id of 16 hex bytes' do
      value = '00-000000000000000000000000000000a-000000000000000a-04'
      proc {
        TraceParent.from_string(value)
      }.must_raise(TraceParent::InvalidFormatError)

      value = '00-0000000000000000000000000000000000a-000000000000000a-04'
      proc {
        TraceParent.from_string(value)
      }.must_raise(TraceParent::InvalidFormatError)
    end

    it 'must have a span_id of 8 hex bytes' do
      proc {
        v = '00-0000000000000000000000000000000a-00000000000a-ff'
        TraceParent.from_string(v)
      }.must_raise TraceParent::InvalidFormatError

      proc {
        v = '00-0000000000000000000000000000000a\
            -0000000000000000000000000000000a-ff'
        TraceParent.from_string(v)
      }.must_raise TraceParent::InvalidFormatError
    end

    it 'must not parse invalid hex' do
      proc do
        v = '00-00000000000z0000000000000000000a-000000000000000a-ff'
        TraceParent.from_string(v)
      end.must_raise TraceParent::InvalidFormatError
    end
  end
end
