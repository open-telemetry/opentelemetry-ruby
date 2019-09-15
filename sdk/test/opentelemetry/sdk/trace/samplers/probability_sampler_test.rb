# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::ProbabilitySampler do
  ProbabilitySampler = OpenTelemetry::SDK::Trace::Samplers::ProbabilitySampler

  describe '#decision' do
    let(:sampler) { ProbabilitySampler.create(Float::MIN) }
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
      positive = ProbabilitySampler.create(1)
      result = call_sampler(positive, trace_id: 'f' * 32)
      result.must_be :sampled?
    end

    it 'returns a false decision if probability is 0' do
      negative = ProbabilitySampler.create(0)
      result = call_sampler(negative, trace_id: trace_id(1))
      result.wont_be :sampled?
    end

    it 'samples the smallest probability larger than the smallest trace_id' do
      probability = 2.0 / (2**64 - 1)
      sampler = ProbabilitySampler.create(probability)
      result = call_sampler(sampler, trace_id: trace_id(1))
      result.must_be :sampled?
    end

    it 'does not sample the largest trace_id with probability less than 1' do
      probability = 1.0.prev_float
      sampler = ProbabilitySampler.create(probability)
      result = call_sampler(sampler, trace_id: trace_id(0xffff_ffff_ffff_ffff))
      result.wont_be :sampled?
    end

    it 'ignores the high bits of the trace_id for sampling' do
      sampler = ProbabilitySampler.create(0.5)
      result = call_sampler(sampler, trace_id: trace_id(0x1_0000_0000_0000_0001))
      result.must_be :sampled?
    end
  end

  describe '#description' do
    let(:sampler) { ProbabilitySampler.create(0.4) }
    it 'returns a String' do
      sampler.description.must_be_kind_of(String)
    end
  end

  describe '.create' do
    it 'limits probability to the range (0...1)' do
      proc { ProbabilitySampler.create(-1) }.must_raise(ArgumentError)
      ProbabilitySampler.create(0).wont_be_nil
      ProbabilitySampler.create(0.5).wont_be_nil
      ProbabilitySampler.create(1).wont_be_nil
      proc { ProbabilitySampler.create(2) }.must_raise(ArgumentError)
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
