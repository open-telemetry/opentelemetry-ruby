# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Tracer do
  Tracer = OpenTelemetry::SDK::Trace::Tracer

  let(:tracer_factory) { OpenTelemetry::SDK::Trace::TracerFactory.new }
  let(:tracer) do
    OpenTelemetry.tracer_factory = tracer_factory
    OpenTelemetry.tracer_factory.tracer
  end
  let(:record_sampler) do
    ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { Result.new(decision: Decision::RECORD) } # rubocop:disable Lint/UnusedBlockArgument
  end

  describe '#name' do
    it 'reflects the name passed in' do
      _(Tracer.new('component', 'semver:1.0').name).must_equal('component')
    end
  end

  describe '#version' do
    it 'reflects the version passed in' do
      _(Tracer.new('component', 'semver:1.0').version).must_equal('semver:1.0')
    end
  end

  describe '#start_root_span' do
    it 'provides a default name' do
      _(tracer.start_root_span(nil).name).wont_be_nil
    end

    it 'returns a valid span' do
      span = tracer.start_root_span('root')
      _(span.context).must_be :valid?
    end

    it 'returns a no-op span if sampler says do not record events' do
      activate_trace_config TraceConfig.new(sampler: Samplers::ALWAYS_OFF)
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).wont_be :sampled?
      _(span).wont_be :recording?
    end

    it 'returns an unsampled span if sampler says record, but do not sample' do
      activate_trace_config TraceConfig.new(sampler: record_sampler)
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).wont_be :sampled?
      _(span).must_be :recording?
    end

    it 'returns a sampled span if sampler says sample' do
      activate_trace_config TraceConfig.new(sampler: Samplers::ALWAYS_ON)
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).must_be :sampled?
      _(span).must_be :recording?
    end

    it 'calls the sampler with all parameters except parent_context' do
      hint = Minitest::Mock.new
      links = Minitest::Mock.new
      name = 'span'
      span_id = OpenTelemetry::Trace.generate_span_id
      trace_id = OpenTelemetry::Trace.generate_trace_id
      kind = Minitest::Mock.new
      attributes = Minitest::Mock.new
      result = Result.new(decision: Decision::NOT_RECORD)
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:call, result, [{ trace_id: trace_id, span_id: span_id, parent_context: nil, hint: hint, links: links, name: name, kind: kind, attributes: attributes }])
      activate_trace_config TraceConfig.new(sampler: mock_sampler)
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        OpenTelemetry::Trace.stub :generate_span_id, span_id do
          tracer.start_root_span(name, attributes: attributes, links: links, kind: kind, sampling_hint: hint)
        end
      end
      mock_sampler.verify
    end

    it 'returns a no-op span if tracer has shutdown' do
      tracer_factory.shutdown
      span = tracer.start_root_span('root')
      _(span.context.trace_flags).wont_be :sampled?
      _(span).wont_be :recording?
    end

    it 'creates a span with all supplied parameters' do
      context = OpenTelemetry::Trace::SpanContext.new
      links = [OpenTelemetry::Trace::Link.new(context)]
      name = 'span'
      kind = OpenTelemetry::Trace::SpanKind::INTERNAL
      attributes = { '1' => 1 }
      start_timestamp = Time.now
      span = tracer.start_root_span(name, attributes: attributes, links: links, kind: kind, start_timestamp: start_timestamp)
      _(span.links).must_equal(links)
      _(span.name).must_equal(name)
      _(span.kind).must_equal(kind)
      _(span.attributes).must_equal(attributes)
      _(span.start_timestamp).must_equal(start_timestamp)
    end

    it 'creates a span with sampler attributes added after supplied attributes' do
      sampler_attributes = { '1' => 1 }
      mock_sampler = Minitest::Mock.new
      result = Result.new(decision: Decision::RECORD, attributes: sampler_attributes)
      mock_sampler.expect(:call, result, [Hash])
      activate_trace_config TraceConfig.new(sampler: mock_sampler)
      span = tracer.start_root_span('op', attributes: { '1' => 0, '2' => 2 })
      _(span.attributes).must_equal('1' => 1, '2' => 2)
    end

    it 'ignores the implicit current span context' do
      root = nil
      span = nil
      tracer.in_span('root') do |s|
        root = s
        span = tracer.start_root_span('also root')
      end
      _(span.parent_span_id).must_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
      _(span.context.trace_id).wont_equal(root.context.trace_id)
    end

    it 'trims link attributes' do
      activate_trace_config TraceConfig.new(max_attributes_per_link: 1)
      link = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '1' => 1, '2' => 2)
      span = tracer.start_root_span('root', links: [link])
      _(span.links.first.attributes.size).must_equal(1)
    end

    it 'trims links' do
      activate_trace_config TraceConfig.new(max_links_count: 1)
      link1 = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '1' => 1)
      link2 = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '2' => 2)
      span = tracer.start_root_span('root', links: [link1, link2])
      _(span.links.size).must_equal(1)
      _(span.links.first).must_equal(link2)
    end
  end

  describe '#start_span' do
    let(:context) { OpenTelemetry::Trace::SpanContext.new }

    it 'provides a default name' do
      _(tracer.start_span(nil, with_parent_context: context).name).wont_be_nil
    end

    it 'returns a valid span' do
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context).must_be :valid?
    end

    it 'returns a span with the same trace ID as the parent context' do
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context.trace_id).must_equal(context.trace_id)
    end

    it 'returns a span with the parent context span ID' do
      span = tracer.start_span('op', with_parent_context: context)
      _(span.parent_span_id).must_equal(context.span_id)
    end

    it 'returns a no-op span if sampler says do not record events' do
      activate_trace_config TraceConfig.new(sampler: Samplers::ALWAYS_OFF)
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context.trace_flags).wont_be :sampled?
      _(span).wont_be :recording?
    end

    it 'returns an unsampled span if sampler says record, but do not sample' do
      activate_trace_config TraceConfig.new(sampler: record_sampler)
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context.trace_flags).wont_be :sampled?
      _(span).must_be :recording?
    end

    it 'returns a sampled span if sampler says sample' do
      activate_trace_config TraceConfig.new(sampler: Samplers::ALWAYS_ON)
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context.trace_flags).must_be :sampled?
      _(span).must_be :recording?
    end

    it 'calls the sampler with all parameters' do
      hint = Minitest::Mock.new
      links = Minitest::Mock.new
      name = 'span'
      span_id = OpenTelemetry::Trace.generate_span_id
      kind = Minitest::Mock.new
      attributes = Minitest::Mock.new
      result = Result.new(decision: Decision::NOT_RECORD)
      mock_sampler = Minitest::Mock.new
      mock_sampler.expect(:call, result, [{ trace_id: context.trace_id, span_id: span_id, parent_context: context, hint: hint, links: links, name: name, kind: kind, attributes: attributes }])
      activate_trace_config TraceConfig.new(sampler: mock_sampler)
      OpenTelemetry::Trace.stub :generate_span_id, span_id do
        tracer.start_span(name, with_parent_context: context, attributes: attributes, links: links, kind: kind, sampling_hint: hint)
      end
      mock_sampler.verify
    end

    it 'returns a no-op span with parent trace ID if tracer has shutdown' do
      tracer_factory.shutdown
      span = tracer.start_span('op', with_parent_context: context)
      _(span.context.trace_flags).wont_be :sampled?
      _(span).wont_be :recording?
      _(span.context.trace_id).must_equal(context.trace_id)
    end

    it 'creates a span with all supplied parameters' do
      links = [OpenTelemetry::Trace::Link.new(context)]
      name = 'span'
      kind = OpenTelemetry::Trace::SpanKind::INTERNAL
      attributes = { '1' => 1 }
      start_timestamp = Time.now
      span = tracer.start_span(name, with_parent_context: context, attributes: attributes, links: links, kind: kind, start_timestamp: start_timestamp)
      _(span.links).must_equal(links)
      _(span.name).must_equal(name)
      _(span.kind).must_equal(kind)
      _(span.attributes).must_equal(attributes)
      _(span.parent_span_id).must_equal(context.span_id)
      _(span.context.trace_id).must_equal(context.trace_id)
      _(span.start_timestamp).must_equal(start_timestamp)
    end

    it 'creates a span with sampler attributes added after supplied attributes' do
      sampler_attributes = { '1' => 1 }
      mock_sampler = Minitest::Mock.new
      result = Result.new(decision: Decision::RECORD, attributes: sampler_attributes)
      mock_sampler.expect(:call, result, [Hash])
      activate_trace_config TraceConfig.new(sampler: mock_sampler)
      span = tracer.start_span('op', with_parent_context: context, attributes: { '1' => 0, '2' => 2 })
      _(span.attributes).must_equal('1' => 1, '2' => 2)
    end

    it 'uses the context from parent span if supplied' do
      parent = tracer.start_root_span('root')
      span = tracer.start_span('child', with_parent: parent)
      _(span.parent_span_id).must_equal(parent.context.span_id)
      _(span.context.trace_id).must_equal(parent.context.trace_id)
    end

    it 'uses the implicit current span context by default' do
      root = nil
      span = nil
      tracer.in_span('root') do |s|
        root = s
        span = tracer.start_span('child')
      end
      _(span.parent_span_id).must_equal(root.context.span_id)
      _(span.context.trace_id).must_equal(root.context.trace_id)
    end

    it 'trims link attributes' do
      activate_trace_config TraceConfig.new(max_attributes_per_link: 1)
      link = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '1' => 1, '2' => 2)
      span = tracer.start_span('op', with_parent_context: context, links: [link])
      _(span.links.first.attributes.size).must_equal(1)
    end

    it 'trims links' do
      activate_trace_config TraceConfig.new(max_links_count: 1)
      link1 = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '1' => 1)
      link2 = OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace::SpanContext.new, '2' => 2)
      span = tracer.start_span('op', with_parent_context: context, links: [link1, link2])
      _(span.links.size).must_equal(1)
      _(span.links.first).must_equal(link2)
    end
  end

  def activate_trace_config(trace_config)
    tracer_factory.active_trace_config = trace_config
  end
end
