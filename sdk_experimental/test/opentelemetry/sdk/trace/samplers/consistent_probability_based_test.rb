# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::ConsistentProbabilityBased do
  subject { OpenTelemetry::SDK::Trace::Samplers::ConsistentProbabilityBased.new(0.5) }

  describe '#description' do
    it 'returns a description' do
      _(subject.description).must_equal('ConsistentProbabilityBased{0.500000}')
    end
  end

  describe '#should_sample?' do
    it 'populates tracestate for a sampled root span' do
      result = call_sampler(subject, trace_id: trace_id(1), parent_context: OpenTelemetry::Context::ROOT)
      _(result.tracestate['ot']).must_equal('p:1;r:62')
      _(result).must_be :sampled?
    end

    it 'populates tracestate for an unsampled root span' do
      result = call_sampler(subject, trace_id: trace_id(-1), parent_context: OpenTelemetry::Context::ROOT)
      _(result.tracestate['ot']).must_equal('r:0')
      _(result).wont_be :sampled?
    end

    it 'populates tracestate with the parent r for a sampled child span' do
      tid = trace_id(1)
      ctx = parent_context(trace_id: tid, ot: 'p:1;r:1')
      result = call_sampler(subject, trace_id: tid, parent_context: ctx)
      _(result.tracestate['ot']).must_equal('p:1;r:1')
      _(result).must_be :sampled?
    end

    it 'populates tracestate without p for an unsampled child span' do
      tid = trace_id(-1)
      ctx = parent_context(trace_id: tid, ot: 'p:0;r:0')
      result = call_sampler(subject, trace_id: tid, parent_context: ctx)
      _(result.tracestate['ot']).must_equal('r:0')
      _(result).wont_be :sampled?
    end

    it 'generates a new r if r is missing in the parent tracestate' do
      tid = trace_id(1)
      ctx = parent_context(trace_id: tid, ot: 'p:1')
      result = call_sampler(subject, trace_id: tid, parent_context: ctx)
      _(result.tracestate['ot']).must_equal('p:1;r:62')
      _(result).must_be :sampled?
    end

    it 'generates a new r if r is invalid in the parent tracestate' do
      tid = trace_id(1)
      ctx = parent_context(trace_id: tid, ot: 'p:1;r:63')
      result = call_sampler(subject, trace_id: tid, parent_context: ctx)
      _(result.tracestate['ot']).must_equal('p:1;r:62')
      _(result).must_be :sampled?
    end

    # TODO: statistical tests
  end

  describe '#initialize' do
    # Check that the internal state is initialized correctly. We cache the
    # floor and ceil of the negative power-of-two of the provided probability,
    # and the probability of the ceil. It should be possible to calculate the
    # original probability from these.
    #
    # Note that these are negative power-of-two exponent values, so the ceiling
    # is the smaller value.

    it 'initializes correctly for power-of-two probabilities' do
      p_values = 62.downto(0)
      probabilities = p_values.map { |i| 2**-i }
      p_values.zip(probabilities).each do |p, probability|
        sampler = OpenTelemetry::SDK::Trace::Samplers::ConsistentProbabilityBased.new(probability)
        _(sampler.instance_variable_get(:@p_floor)).must_equal(p)
        _(sampler.instance_variable_get(:@p_ceil)).must_equal(p-1)
        _(sampler.instance_variable_get(:@p_ceil_probability)).must_equal(0)
      end
    end

    it 'initializes correctly for 0.1' do
      sampler = OpenTelemetry::SDK::Trace::Samplers::ConsistentProbabilityBased.new(0.1)
      _(sampler.instance_variable_get(:@p_floor)).must_equal(4) # 2**-4 = 0.0625
      _(sampler.instance_variable_get(:@p_ceil)).must_equal(3) # 2**-3 = 0.125
      _(sampler.instance_variable_get(:@p_ceil_probability)).must_be_within_epsilon(0.6) # 0.0375 / 0.0625
      ceil_prob = sampler.instance_variable_get(:@p_ceil_probability)
      floor_prob = 1 - ceil_prob
      p_floor = sampler.instance_variable_get(:@p_floor)
      p_ceil = sampler.instance_variable_get(:@p_ceil)
      _((2**-p_ceil * ceil_prob) + (2**-p_floor * floor_prob)).must_be_within_epsilon(0.1)
    end
  end
end
