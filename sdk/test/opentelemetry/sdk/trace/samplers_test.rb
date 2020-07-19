# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers do
  Samplers = OpenTelemetry::SDK::Trace::Samplers

  describe '.ALWAYS_ON' do
    it 'samples' do
      _(call_sampler(Samplers::ALWAYS_ON)).must_be :sampled?
    end
  end

  describe '.ALWAYS_OFF' do
    it 'does not sample' do
      _(call_sampler(Samplers::ALWAYS_OFF)).wont_be :sampled?
    end
  end

  describe '.parent_or_else' do
    let(:sampler) { Samplers.parent_or_else(Samplers::ALWAYS_OFF) }

    it 'samples if parent is sampled' do
      context = OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(1)
      )
      _(call_sampler(sampler, parent_context: context)).must_be :sampled?
    end

    it 'does not sample if parent is not sampled' do
      context = OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(0)
      )
      _(call_sampler(sampler, parent_context: context)).wont_be :sampled?
    end

    it 'delegates sampling of root spans' do
      trace_id = OpenTelemetry::Trace.generate_trace_id
      result = Result.new(decision: Decision::NOT_RECORD)
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: nil, links: nil, name: nil, kind: nil, attributes: nil }])
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        _(call_sampler(Samplers.parent_or_else(mock_sampler), parent_context: nil)).wont_be :sampled?
      end
      mock_sampler.verify
    end
  end

  describe '.probability' do
    let(:sampler) { Samplers.probability(Float::MIN) }
    let(:context) do
      OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(1)
      )
    end

    it 'respects parent sampling' do
      result = call_sampler(sampler, parent_context: context)
      _(result).must_be :sampled?
    end

    it 'ignores parent sampling if ignore_parent' do
      sampler = Samplers.probability(Float::MIN, ignore_parent: true)
      result = call_sampler(sampler, parent_context: context, trace_id: trace_id(123))
      _(result).wont_be :sampled?
    end

    it 'returns a result' do
      result = call_sampler(sampler, trace_id: trace_id(123))
      _(result).must_be_instance_of(Result)
    end

    it 'samples if probability is 1' do
      positive = Samplers.probability(1)
      result = call_sampler(positive, trace_id: 'f' * 32)
      _(result).must_be :sampled?
    end

    it 'does not sample if probability is 0' do
      sampler = Samplers.probability(0)
      result = call_sampler(sampler, trace_id: trace_id(1))
      _(result).wont_be :sampled?
    end

    it 'does not sample a remote parent if apply_probability_to == :root_spans' do
      context = OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(0),
        remote: true
      )
      sampler = Samplers.probability(1, apply_probability_to: :root_spans)
      result = call_sampler(sampler, parent_context: context)
      _(result).wont_be :sampled?
    end

    it 'samples a local child span if apply_probability_to == :all_spans' do
      sampler = Samplers.probability(1, apply_probability_to: :all_spans)
      result = call_sampler(sampler, parent_context: context, trace_id: trace_id(1))
      _(result).must_be :sampled?
    end

    it 'samples a remote parent if apply_probability_to == :root_spans_and_remote_parent' do
      context = OpenTelemetry::Trace::SpanContext.new(
        trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(0),
        remote: true
      )
      sampler = Samplers.probability(1, apply_probability_to: :root_spans_and_remote_parent)
      result = call_sampler(sampler, parent_context: context)
      _(result).must_be :sampled?
    end

    it 'does not sample a local child span if apply_probability_to == :root_spans_and_remote_parent' do
      context = OpenTelemetry::Trace::SpanContext.new(trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(0))
      sampler = Samplers.probability(1, apply_probability_to: :root_spans_and_remote_parent)
      result = call_sampler(sampler, parent_context: context, trace_id: trace_id(1))
      _(result).wont_be :sampled?
    end

    it 'does not sample a local child span if apply_probability_to == :root_spans' do
      context = OpenTelemetry::Trace::SpanContext.new(trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(0))
      sampler = Samplers.probability(1, apply_probability_to: :root_spans)
      result = call_sampler(sampler, parent_context: context, trace_id: trace_id(1))
      _(result).wont_be :sampled?
    end

    it 'does not allow invalid symbols in apply_probability_to' do
      _(proc { Samplers.probability(1, apply_probability_to: :foo) }).must_raise(ArgumentError)
    end

    it 'samples the smallest probability larger than the smallest trace_id' do
      probability = 2.0 / (2**64 - 1)
      sampler = Samplers.probability(probability)
      result = call_sampler(sampler, trace_id: trace_id(1))
      _(result).must_be :sampled?
    end

    it 'does not sample the largest trace_id with probability less than 1' do
      probability = 1.0.prev_float
      sampler = Samplers.probability(probability)
      result = call_sampler(sampler, trace_id: trace_id(0xffff_ffff_ffff_ffff))
      _(result).wont_be :sampled?
    end

    it 'ignores the high bits of the trace_id for sampling' do
      sampler = Samplers.probability(0.5)
      result = call_sampler(sampler, trace_id: trace_id(0x1_0000_0000_0000_0001))
      _(result).must_be :sampled?
    end

    it 'limits probability to the range (0...1)' do
      _(proc { Samplers.probability(-1) }).must_raise(ArgumentError)
      _(Samplers.probability(0)).wont_be_nil
      _(Samplers.probability(0.5)).wont_be_nil
      _(Samplers.probability(1)).wont_be_nil
      _(proc { Samplers.probability(2) }).must_raise(ArgumentError)
    end
  end

  def trace_id(id)
    first = id >> 64
    second = id & 0xffff_ffff_ffff_ffff
    [first, second].pack('Q>Q>')
  end

  def call_sampler(sampler, trace_id: nil, parent_context: nil, links: nil, name: nil, kind: nil, attributes: nil)
    sampler.should_sample?(
      trace_id: trace_id || OpenTelemetry::Trace.generate_trace_id,
      parent_context: parent_context,
      links: links,
      name: name,
      kind: kind,
      attributes: attributes
    )
  end
end
