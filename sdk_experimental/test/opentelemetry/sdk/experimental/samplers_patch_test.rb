# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Experimental::SamplersPatch do
  it 'upgrades Samplers' do
    _(OpenTelemetry::SDK::Trace::Samplers).must_respond_to(:parent_consistent_probability_based)
    _(OpenTelemetry::SDK::Trace::Samplers).must_respond_to(:consistent_probability_based)
  end

  describe '#parent_consistent_probability_based' do
    it 'returns a ParentConsistentProbabilityBased sampler' do
      sampler = OpenTelemetry::SDK::Trace::Samplers.parent_consistent_probability_based(root: OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON)
      _(sampler).must_be_instance_of(OpenTelemetry::SDK::Trace::Samplers::ParentConsistentProbabilityBased)
    end
  end

  describe '#consistent_probability_based' do
    it 'returns a ConsistentProbabilityBased sampler' do
      sampler = OpenTelemetry::SDK::Trace::Samplers.consistent_probability_based(0.5)
      _(sampler).must_be_instance_of(OpenTelemetry::SDK::Trace::Samplers::ConsistentProbabilityBased)
    end

    it 'complains if ratio is out of range' do
      _(proc { OpenTelemetry::SDK::Trace::Samplers.consistent_probability_based(1.1) }).must_raise(ArgumentError)
      _(proc { OpenTelemetry::SDK::Trace::Samplers.consistent_probability_based(-0.1) }).must_raise(ArgumentError)
    end
  end
end
