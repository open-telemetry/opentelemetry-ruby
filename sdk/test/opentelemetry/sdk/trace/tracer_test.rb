# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Tracer do
  Tracer = OpenTelemetry::SDK::Trace::Tracer

  let(:tracer) { Tracer.new }
  let(:record_sampler) do
    ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { Result.new(decision: Decision::RECORD) } # rubocop:disable Lint/UnusedBlockArgument
  end

  describe '#create_event' do
    it 'trims event attributes' do
      tracer.active_trace_config = TraceConfig.new(max_attributes_per_event: 1)
      event = tracer.create_event(name: 'event', attributes: { '1' => 1, '2' => 2 })
      event.attributes.size.must_equal(1)
    end
  end

  describe '#create_link' do
    it 'trims link attributes' do
      tracer.active_trace_config = TraceConfig.new(max_attributes_per_link: 1)
      link = tracer.create_link(OpenTelemetry::Trace::SpanContext.new, '1' => 1, '2' => 2)
      link.attributes.size.must_equal(1)
    end
  end

  describe '#initialize' do
    # TODO
  end

  describe '#shutdown' do
    # TODO
  end

  describe '#add_span_processor' do
    # TODO
  end

  describe '#start_root_span' do
    it 'requires a name' do
      proc { tracer.start_root_span(nil) }.must_raise(ArgumentError)
    end

    it 'returns a valid span' do
      span = tracer.start_root_span('root')
      span.context.must_be :valid?
    end

    it 'returns a no-op span if sampler says do not record events' do
      tracer.active_trace_config = TraceConfig.new(sampler: Samplers::ALWAYS_OFF)
      span = tracer.start_root_span('root')
      span.context.trace_flags.wont_be :sampled?
      span.wont_be :recording_events?
    end

    it 'returns an unsampled span if sampler says record, but do not sample' do
      tracer.active_trace_config = TraceConfig.new(sampler: record_sampler)
      span = tracer.start_root_span('root')
      span.context.trace_flags.wont_be :sampled?
      span.must_be :recording_events?
    end

    it 'returns a sampled span if sampler says sample' do
      tracer.active_trace_config = TraceConfig.new(sampler: Samplers::ALWAYS_ON)
      span = tracer.start_root_span('root')
      span.context.trace_flags.must_be :sampled?
      span.must_be :recording_events?
    end

    it 'calls the sampler with all parameters except parent_context' do
      # TODO
    end

    # TODO
  end

  describe '#start_span' do
    # TODO
  end
end
