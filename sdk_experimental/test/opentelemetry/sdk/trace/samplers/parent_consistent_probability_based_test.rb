# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::ParentConsistentProbabilityBased do
  subject { OpenTelemetry::SDK::Trace::Samplers::ParentConsistentProbabilityBased.new(OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON) }

  describe '#description' do
    it 'returns a description' do
      _(subject.description).must_equal('ParentConsistentProbabilityBased{root=AlwaysOnSampler}')
    end
  end

  describe '#should_sample?' do
    it 'delegates to the root sampler for root spans' do
      result = call_sampler(subject, parent_context: OpenTelemetry::Context::ROOT)
      _(result).must_be :sampled?
    end

    it 'does not modify valid tracestate' do
      _(call_sampler(subject, parent_context: parent_context(ot: 'junk;p:1;r:0')).tracestate['ot']).must_equal('junk;p:1;r:0')
    end

    it 'sanitizes input tracestate' do
      _(call_sampler(subject, parent_context: parent_context(ot: 'junk;p:1;r:1')).tracestate['ot']).must_equal('r:1;junk')
      _(call_sampler(subject, parent_context: parent_context(ot: 'p:64;r:1')).tracestate['ot']).must_equal('r:1')
      _(call_sampler(subject, parent_context: parent_context(sampled: false, ot: 'p:2;r:1')).tracestate['ot']).must_equal('p:2;r:1')
      _(call_sampler(subject, parent_context: parent_context(sampled: true, ot: 'p:2;r:1')).tracestate['ot']).must_equal('r:1')
      _(call_sampler(subject, parent_context: parent_context(sampled: true, ot: 'p:63;r:1')).tracestate['ot']).must_equal('p:63;r:1')
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(ot: 'p:1;r:63')).tracestate['ot']).must_equal('r:0')
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(ot: 'p:1;r:63;junk')).tracestate['ot']).must_equal('r:0;junk')
    end

    it 'sets r based on the trace_id if missing or invalid' do
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(sampled: true)).tracestate['ot']).must_equal('r:0')
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(sampled: false)).tracestate['ot']).must_equal('r:0')
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(ot: 'r:63', sampled: true)).tracestate['ot']).must_equal('r:0')
      _(call_sampler(subject, trace_id: trace_id(-1), parent_context: parent_context(ot: 'r:63', sampled: false)).tracestate['ot']).must_equal('r:0')
    end

    it 'respects parent sampling decision' do
      _(call_sampler(subject, parent_context: parent_context(sampled: true, ot: 'p:2;r:1'))).must_be :sampled?
      _(call_sampler(subject, parent_context: parent_context(sampled: false, ot: 'p:2;r:1'))).wont_be :sampled?
      _(call_sampler(subject, parent_context: parent_context(sampled: true, ot: 'p:1;r:2'))).must_be :sampled?
      _(call_sampler(subject, parent_context: parent_context(sampled: false, ot: 'p:1;r:2'))).wont_be :sampled?
    end
  end
end
