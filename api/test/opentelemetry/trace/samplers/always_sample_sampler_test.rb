# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Samplers::AlwaysSampleSampler do
  let(:sampler) { OpenTelemetry::Trace::Samplers::AlwaysSampleSampler.new }
  describe '.description' do
    it 'returns a description' do
      sampler.description.must_equal('AlwaysSampleSampler')
    end
  end
  describe '.should_sample' do
    it 'returns a true decision' do
      decision = sampler.should_sample(
        span_context: nil,
        extracted_context: nil,
        trace_id: 344,
        span_id: 178,
        span_name: 'test_span',
        links: nil
      )
      decision.sampled?.must_equal(true)
    end
  end
end
