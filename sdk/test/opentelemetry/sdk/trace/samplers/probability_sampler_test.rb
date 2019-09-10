# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::ProbabilitySampler do
  ProbabilitySampler = OpenTelemetry::SDK::Trace::Samplers::ProbabilitySampler
  Sampler = OpenTelemetry::Trace::Samplers::Sampler
  SpanContext = OpenTelemetry::Trace::SpanContext
  TraceFlags = OpenTelemetry::Trace::TraceFlags
  Link = OpenTelemetry::Trace::Link
  Decision = OpenTelemetry::Trace::Samplers::Decision

  describe '#decision' do
    let(:context) { SpanContext.new(trace_flags: TraceFlags.from_byte(1)) }
    let(:sampler) { ProbabilitySampler.create(Float::MIN) }
    it 'respects parent sample decision' do
      decision = sampler.decision(
        trace_id: 123,
        span_id: 456,
        span_name: '',
        span_context: context
      )
      decision.must_be :sampled?
    end
    it 'respects link sample decisions' do
      link = OpenTelemetry::Trace::Link.new(span_context: context)
      decision = sampler.decision(
        trace_id: 123,
        span_id: 456,
        span_name: '',
        links: [link]
      )
      decision.must_be :sampled?
    end
    it 'returns a decision' do
      decision = sampler.decision(trace_id: 123, span_id: 456, span_name: '')
      decision.must_be_instance_of(Decision)
    end
    it 'returns a true decision if probability is 1' do
      positive = ProbabilitySampler.create(1)
      decision = positive.decision(trace_id: 123, span_id: 456, span_name: '')
      decision.must_be :sampled?
    end
    it 'returns a false decision if probability is 0' do
      negative = ProbabilitySampler.create(0)
      decision = negative.decision(trace_id: 123, span_id: 456, span_name: '')
      decision.wont_be :sampled?
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
    it 'returns a Sampler' do
      ProbabilitySampler.create(0).must_be_kind_of(Sampler)
      ProbabilitySampler.create(0.5).must_be_kind_of(Sampler)
      ProbabilitySampler.create(1).must_be_kind_of(Sampler)
    end
  end
end
