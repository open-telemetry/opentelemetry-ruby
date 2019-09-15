# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers do
  Samplers = OpenTelemetry::SDK::Trace::Samplers

  describe '.probability' do
    let(:sampler) { Samplers.probability(Float::MIN) }
    let(:context) do
      OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(1)
      )
    end

    it 'respects parent sampling' do
      result = call_sampler(sampler, parent_context: context)
      result.must_be :sampled?
    end

    it 'respects link sampling' do
      link = OpenTelemetry::Trace::Link.new(span_context: context)
      result = call_sampler(sampler, links: [link])
      result.must_be :sampled?
    end

    it 'returns a result' do
      result = call_sampler(sampler, trace_id: trace_id(123))
      result.must_be_instance_of(Result)
    end

    it 'returns a true decision if probability is 1' do
      positive = Samplers.probability(1)
      result = call_sampler(positive, trace_id: 'f' * 32)
      result.must_be :sampled?
    end

    it 'returns a false decision if probability is 0' do
      negative = Samplers.probability(0)
      result = call_sampler(negative, trace_id: trace_id(1))
      result.wont_be :sampled?
    end

    it 'samples the smallest probability larger than the smallest trace_id' do
      probability = 2.0 / (2**64 - 1)
      sampler = Samplers.probability(probability)
      result = call_sampler(sampler, trace_id: trace_id(1))
      result.must_be :sampled?
    end

    it 'does not sample the largest trace_id with probability less than 1' do
      probability = 1.0.prev_float
      sampler = Samplers.probability(probability)
      result = call_sampler(sampler, trace_id: trace_id(0xffff_ffff_ffff_ffff))
      result.wont_be :sampled?
    end

    it 'ignores the high bits of the trace_id for sampling' do
      sampler = Samplers.probability(0.5)
      result = call_sampler(sampler, trace_id: trace_id(0x1_0000_0000_0000_0001))
      result.must_be :sampled?
    end

    it 'limits probability to the range (0...1)' do
      proc { Samplers.probability(-1) }.must_raise(ArgumentError)
      Samplers.probability(0).wont_be_nil
      Samplers.probability(0.5).wont_be_nil
      Samplers.probability(1).wont_be_nil
      proc { Samplers.probability(2) }.must_raise(ArgumentError)
    end
  end

  def trace_id(id)
    format('%032x', id)
  end

  def call_sampler(sampler, trace_id: nil, span_id: nil, parent_context: nil, hint: nil, links: nil, name: nil, kind: nil, attributes: nil)
    sampler.call(
      trace_id: trace_id,
      span_id: span_id,
      parent_context: parent_context,
      hint: hint,
      links: links,
      name: name,
      kind: kind,
      attributes: attributes
    )
  end
end
