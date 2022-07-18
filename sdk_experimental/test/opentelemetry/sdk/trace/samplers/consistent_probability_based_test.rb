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
end