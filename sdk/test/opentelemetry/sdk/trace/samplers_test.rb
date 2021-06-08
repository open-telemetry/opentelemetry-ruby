# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers do
  Samplers = OpenTelemetry::SDK::Trace::Samplers

  let(:tracestate) { Object.new }
  let(:context_with_tracestate) do
    span_context = OpenTelemetry::Trace::SpanContext.new(trace_id: OpenTelemetry::Trace.generate_trace_id, tracestate: tracestate)
    OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(span_context))
  end

  describe '.ALWAYS_ON' do
    it 'samples' do
      _(call_sampler(Samplers::ALWAYS_ON)).must_be :sampled?
    end

    it 'passes through the tracestate from context' do
      _(call_sampler(Samplers::ALWAYS_ON, parent_context: context_with_tracestate).tracestate).must_equal tracestate
    end
  end

  describe '.ALWAYS_OFF' do
    it 'does not sample' do
      _(call_sampler(Samplers::ALWAYS_OFF)).wont_be :sampled?
    end

    it 'passes through the tracestate from context' do
      _(call_sampler(Samplers::ALWAYS_ON, parent_context: context_with_tracestate).tracestate).must_equal tracestate
    end
  end

  describe '.parent_based' do
    let(:not_a_sampler) { Minitest::Mock.new }
    let(:trace_id) { OpenTelemetry::Trace.generate_trace_id }
    let(:result) { Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: nil) }
    let(:sampled) { OpenTelemetry::Trace::TraceFlags.from_byte(1) }
    let(:not_sampled) { OpenTelemetry::Trace::TraceFlags.from_byte(0) }
    let(:remote_sampled_parent_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, remote: true, trace_flags: sampled) }
    let(:remote_not_sampled_parent_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, remote: true, trace_flags: not_sampled) }
    let(:local_sampled_parent_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, remote: false, trace_flags: sampled) }
    let(:local_not_sampled_parent_span_context) { OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, remote: false, trace_flags: not_sampled) }
    let(:remote_sampled_parent_context) { OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(remote_sampled_parent_span_context)) }
    let(:remote_not_sampled_parent_context) { OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(remote_not_sampled_parent_span_context)) }
    let(:local_sampled_parent_context) { OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(local_sampled_parent_span_context)) }
    let(:local_not_sampled_parent_context) { OpenTelemetry::Trace.context_with_span(OpenTelemetry::Trace.non_recording_span(local_not_sampled_parent_span_context)) }

    it 'provides defaults for parent samplers' do
      sampler = Samplers.parent_based(root: not_a_sampler)
      _(call_sampler(sampler, parent_context: remote_sampled_parent_context)).must_be :sampled?
      _(call_sampler(sampler, parent_context: remote_not_sampled_parent_context)).wont_be :sampled?
      _(call_sampler(sampler, parent_context: local_sampled_parent_context)).must_be :sampled?
      _(call_sampler(sampler, parent_context: local_not_sampled_parent_context)).wont_be :sampled?
    end

    it 'delegates sampling of remote sampled spans' do
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: remote_sampled_parent_context, links: nil, name: nil, kind: nil, attributes: nil }])
      sampler = Samplers.parent_based(
        root: not_a_sampler,
        remote_parent_sampled: mock_sampler,
        remote_parent_not_sampled: not_a_sampler,
        local_parent_sampled: not_a_sampler,
        local_parent_not_sampled: not_a_sampler
      )
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        call_sampler(sampler, parent_context: remote_sampled_parent_context)
      end
      mock_sampler.verify
    end

    it 'delegates sampling of remote not sampled spans' do
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: remote_not_sampled_parent_context, links: nil, name: nil, kind: nil, attributes: nil }])
      sampler = Samplers.parent_based(
        root: not_a_sampler,
        remote_parent_sampled: not_a_sampler,
        remote_parent_not_sampled: mock_sampler,
        local_parent_sampled: not_a_sampler,
        local_parent_not_sampled: not_a_sampler
      )
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        call_sampler(sampler, parent_context: remote_not_sampled_parent_context)
      end
      mock_sampler.verify
    end

    it 'delegates sampling of local sampled spans' do
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: local_sampled_parent_context, links: nil, name: nil, kind: nil, attributes: nil }])
      sampler = Samplers.parent_based(
        root: not_a_sampler,
        remote_parent_sampled: not_a_sampler,
        remote_parent_not_sampled: not_a_sampler,
        local_parent_sampled: mock_sampler,
        local_parent_not_sampled: not_a_sampler
      )
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        call_sampler(sampler, parent_context: local_sampled_parent_context)
      end
      mock_sampler.verify
    end

    it 'delegates sampling of local not sampled spans' do
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: local_not_sampled_parent_context, links: nil, name: nil, kind: nil, attributes: nil }])
      sampler = Samplers.parent_based(
        root: not_a_sampler,
        remote_parent_sampled: not_a_sampler,
        remote_parent_not_sampled: not_a_sampler,
        local_parent_sampled: not_a_sampler,
        local_parent_not_sampled: mock_sampler
      )
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        call_sampler(sampler, parent_context: local_not_sampled_parent_context)
      end
      mock_sampler.verify
    end

    it 'delegates sampling of root spans' do
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:should_sample?, result, [{ trace_id: trace_id, parent_context: nil, links: nil, name: nil, kind: nil, attributes: nil }])
      sampler = Samplers.parent_based(
        root: mock_sampler,
        remote_parent_sampled: not_a_sampler,
        remote_parent_not_sampled: not_a_sampler,
        local_parent_sampled: not_a_sampler,
        local_parent_not_sampled: not_a_sampler
      )
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        call_sampler(sampler, parent_context: nil)
      end
      mock_sampler.verify
    end
  end

  describe '.trace_id_ratio_based' do
    let(:sampler) { Samplers.trace_id_ratio_based(Float::MIN) }

    it 'ignores parent sampling' do
      sampler = Samplers.trace_id_ratio_based(Float::MIN)
      span_context = OpenTelemetry::Trace::SpanContext.new(trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(1))
      span = OpenTelemetry::Trace.non_recording_span(span_context)
      parent_context = OpenTelemetry::Trace.context_with_span(span)
      result = call_sampler(sampler, parent_context: parent_context, trace_id: trace_id(123))
      _(result).wont_be :sampled?
    end

    it 'returns a result' do
      result = call_sampler(sampler, trace_id: trace_id(123))
      _(result).must_be_instance_of(Result)
    end

    it 'passes through the tracestate from context' do
      _(call_sampler(sampler, parent_context: context_with_tracestate).tracestate).must_equal tracestate
    end

    it 'samples if ratio is 1' do
      positive = Samplers.trace_id_ratio_based(1)
      result = call_sampler(positive, trace_id: 'f' * 32)
      _(result).must_be :sampled?
    end

    it 'does not sample if ratio is 0' do
      sampler = Samplers.trace_id_ratio_based(0)
      result = call_sampler(sampler, trace_id: trace_id(1))
      _(result).wont_be :sampled?
    end

    it 'samples the smallest ratio larger than the smallest trace_id' do
      ratio = 2.0 / (2**64 - 1)
      sampler = Samplers.trace_id_ratio_based(ratio)
      result = call_sampler(sampler, trace_id: trace_id(1))
      _(result).must_be :sampled?
    end

    it 'does not sample the largest trace_id with ratio less than 1' do
      ratio = 1.0.prev_float
      sampler = Samplers.trace_id_ratio_based(ratio)
      result = call_sampler(sampler, trace_id: trace_id(0xffff_ffff_ffff_ffff))
      _(result).wont_be :sampled?
    end

    it 'ignores the high bits of the trace_id for sampling' do
      sampler = Samplers.trace_id_ratio_based(0.5)
      result = call_sampler(sampler, trace_id: trace_id(0x1_0000_0000_0000_0001))
      _(result).must_be :sampled?
    end

    it 'limits ratio to the range (0...1)' do
      _(proc { Samplers.trace_id_ratio_based(-1) }).must_raise(ArgumentError)
      _(Samplers.trace_id_ratio_based(0)).wont_be_nil
      _(Samplers.trace_id_ratio_based(0.5)).wont_be_nil
      _(Samplers.trace_id_ratio_based(1)).wont_be_nil
      _(proc { Samplers.trace_id_ratio_based(2) }).must_raise(ArgumentError)
    end
  end

  def trace_id(id)
    first = id >> 64
    second = id & 0xffff_ffff_ffff_ffff
    [first, second].pack('Q>Q>')
  end

  def call_sampler(sampler, trace_id: nil, parent_context: OpenTelemetry::Context.current, links: nil, name: nil, kind: nil, attributes: nil)
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
