# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Samplers::Sampler do
  class BasicSampler < OpenTelemetry::Trace::Samplers::Sampler
    DECISION = OpenTelemetry::Trace::Samplers::Decision.new(decision: true)
    def decision(span_context: nil,
                 extracted_context: nil,
                 trace_id:,
                 span_id:,
                 span_name:,
                 links: nil)
      super
      DECISION
    end

    def description
      'BasicSampler'
    end
  end

  let(:sampler) { BasicSampler.new }
  describe '.decision' do
    it 'returns a decision with required arguments' do
      decision = sampler.decision(
        span_context: nil,
        extracted_context: nil,
        trace_id: '344',
        span_id: '178',
        span_name: 'test_span',
        links: nil
      )
      decision.must_be_instance_of(OpenTelemetry::Trace::Samplers::Decision)
    end

    it 'checks span_context for type' do
      proc do
        sampler.decision(
          span_context: Object.new,
          extracted_context: nil,
          trace_id: '344',
          span_id: '178',
          span_name: 'test_span',
          links: nil
        )
      end.must_raise(ArgumentError)
    end

    it 'checks extracted_context for type' do
      proc do
        sampler.decision(
          span_context: nil,
          extracted_context: Object.new,
          trace_id: '344',
          span_id: '178',
          span_name: 'test_span',
          links: nil
        )
      end.must_raise(ArgumentError)
    end

    it 'checks trace_id for type' do
      proc do
        sampler.decision(
          span_context: nil,
          extracted_context: nil,
          trace_id: Object.new,
          span_id: '178',
          span_name: 'test_span',
          links: nil
        )
      end.must_raise(ArgumentError)
    end

    it 'checks span_id for type' do
      proc do
        sampler.decision(
          span_context: nil,
          extracted_context: nil,
          trace_id: '344',
          span_id: Object.new,
          span_name: 'test_span',
          links: nil
        )
      end.must_raise(ArgumentError)
    end

    it 'checks span_name for type' do
      proc do
        sampler.decision(
          span_context: nil,
          extracted_context: nil,
          trace_id: '344',
          span_id: '178',
          span_name: Object.new,
          links: nil
        )
      end.must_raise(ArgumentError)
    end

    it 'checks that links are enumerable' do
      proc do
        sampler.decision(
          span_context: nil,
          extracted_context: nil,
          trace_id: '344',
          span_id: '178',
          span_name: 'test_span',
          links: Object.new
        )
      end.must_raise(ArgumentError)
    end
  end
end
