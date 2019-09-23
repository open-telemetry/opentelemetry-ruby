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

    it 'returns an event with the given name, attributes, timestamp' do
      ts = Time.now
      event = tracer.create_event(name: 'event', attributes: { '1' => 1 }, timestamp: ts)
      event.attributes.must_equal('1' => 1)
      event.name.must_equal('event')
      event.timestamp.must_equal(ts)
    end

    it 'returns an event with no attributes by default' do
      event = tracer.create_event(name: 'event')
      event.attributes.must_equal({})
    end

    it 'returns an event with a default timestamp' do
      event = tracer.create_event(name: 'event')
      event.timestamp.wont_be_nil
    end
  end

  describe '#create_link' do
    it 'trims link attributes' do
      tracer.active_trace_config = TraceConfig.new(max_attributes_per_link: 1)
      link = tracer.create_link(OpenTelemetry::Trace::SpanContext.new, '1' => 1, '2' => 2)
      link.attributes.size.must_equal(1)
    end

    it 'returns a link with the given span context and attributes' do
      context = OpenTelemetry::Trace::SpanContext.new
      link = tracer.create_link(context, '1' => 1)
      link.attributes.must_equal('1' => 1)
      link.context.must_equal(context)
    end

    it 'returns a link with no attributes by default' do
      link = tracer.create_link(OpenTelemetry::Trace::SpanContext.new)
      link.attributes.must_equal({})
    end
  end

  describe '#initialize' do
    it 'installs a Resource' do
      Tracer.new.resource.wont_be_nil
    end

    it 'activates a default TraceConfig' do
      Tracer.new.active_trace_config.must_equal(TraceConfig::DEFAULT)
    end
  end

  describe '#shutdown' do
    let(:mock_span_processor) { Minitest::Mock.new }

    it 'notifies the span processor' do
      mock_span_processor.expect(:shutdown, nil)
      tracer.add_span_processor(mock_span_processor)
      tracer.shutdown
      mock_span_processor.verify
    end

    it 'warns if called more than once' do
      mock_logger = Minitest::Mock.new
      mock_logger.expect(:warn, nil, [String])
      OpenTelemetry.stub :logger, mock_logger do
        tracer.shutdown
        tracer.shutdown
      end
      mock_logger.verify
    end

    it 'only notifies the span processor once' do
      mock_span_processor.expect(:shutdown, nil)
      tracer.add_span_processor(mock_span_processor)
      tracer.shutdown
      tracer.shutdown
      mock_span_processor.verify
    end
  end

  describe '#add_span_processor' do
    it 'does not add the processor if stopped' do
      mock_span_processor = Minitest::Mock.new
      tracer.shutdown
      tracer.add_span_processor(mock_span_processor)
      tracer.in_span('span') {}
      mock_span_processor.verify
    end

    it 'adds the span processor to the active span processors' do
      mock_span_processor = Minitest::Mock.new
      mock_span_processor.expect(:on_start, nil, [Span])
      tracer.add_span_processor(mock_span_processor)
      tracer.in_span('span') {}
      mock_span_processor.verify
    end
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
      tracer.active_trace_config = TraceConfig.new(sampler: mock_sampler)
      OpenTelemetry::Trace.stub :generate_trace_id, trace_id do
        OpenTelemetry::Trace.stub :generate_span_id, span_id do
          tracer.start_root_span(name, attributes: attributes, links: links, kind: kind, sampling_hint: hint)
        end
      end
      mock_sampler.verify
    end

    it 'returns a no-op span if tracer has shutdown' do
      tracer.shutdown
      span = tracer.start_root_span('root')
      span.context.trace_flags.wont_be :sampled?
      span.wont_be :recording_events?
    end

    it 'creates a span with all supplied parameters' do
      context = OpenTelemetry::Trace::SpanContext.new
      links = [Link.new(span_context: context, attributes: nil)]
      name = 'span'
      kind = OpenTelemetry::Trace::SpanKind::INTERNAL
      attributes = { '1' => 1 }
      start_timestamp = Time.now
      span = tracer.start_root_span(name, attributes: attributes, links: links, kind: kind, start_timestamp: start_timestamp)
      span.links.must_equal(links)
      span.name.must_equal(name)
      span.kind.must_equal(kind)
      span.attributes.must_equal(attributes)
      span.start_timestamp.must_equal(start_timestamp)
    end

    it 'creates a span with sampler attributes added after supplied attributes' do
      sampler_attributes = { '1' => 1 }
      mock_sampler = Minitest::Mock.new
      result = Result.new(decision: Decision::RECORD, attributes: sampler_attributes)
      mock_sampler.expect(:call, result, [Hash])
      tracer.active_trace_config = TraceConfig.new(sampler: mock_sampler)
      span = tracer.start_root_span('op', attributes: { '1' => 0, '2' => 2 })
      span.attributes.must_equal('1' => 1, '2' => 2)
    end

    it 'ignores the implicit current span context' do
      root = nil
      span = nil
      tracer.in_span('root') do |s|
        root = s
        span = tracer.start_root_span('also root')
      end
      span.parent_span_id.must_equal(OpenTelemetry::Trace::INVALID_SPAN_ID)
      span.context.trace_id.wont_equal(root.context.trace_id)
    end
  end

  describe '#start_span' do
    let(:context) { OpenTelemetry::Trace::SpanContext.new }

    it 'requires a name' do
      proc { tracer.start_span(nil, with_parent_context: context) }.must_raise(ArgumentError)
    end

    it 'returns a valid span' do
      span = tracer.start_span('op', with_parent_context: context)
      span.context.must_be :valid?
    end

    it 'returns a span with the same trace ID as the parent context' do
      span = tracer.start_span('op', with_parent_context: context)
      span.context.trace_id.must_equal(context.trace_id)
    end

    it 'returns a span with the parent context span ID' do
      span = tracer.start_span('op', with_parent_context: context)
      span.parent_span_id.must_equal(context.span_id)
    end

    it 'returns a no-op span if sampler says do not record events' do
      tracer.active_trace_config = TraceConfig.new(sampler: Samplers::ALWAYS_OFF)
      span = tracer.start_span('op', with_parent_context: context)
      span.context.trace_flags.wont_be :sampled?
      span.wont_be :recording_events?
    end

    it 'returns an unsampled span if sampler says record, but do not sample' do
      tracer.active_trace_config = TraceConfig.new(sampler: record_sampler)
      span = tracer.start_span('op', with_parent_context: context)
      span.context.trace_flags.wont_be :sampled?
      span.must_be :recording_events?
    end

    it 'returns a sampled span if sampler says sample' do
      tracer.active_trace_config = TraceConfig.new(sampler: Samplers::ALWAYS_ON)
      span = tracer.start_span('op', with_parent_context: context)
      span.context.trace_flags.must_be :sampled?
      span.must_be :recording_events?
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
      tracer.active_trace_config = TraceConfig.new(sampler: mock_sampler)
      OpenTelemetry::Trace.stub :generate_span_id, span_id do
        tracer.start_span(name, with_parent_context: context, attributes: attributes, links: links, kind: kind, sampling_hint: hint)
      end
      mock_sampler.verify
    end

    it 'returns a no-op span with parent trace ID if tracer has shutdown' do
      tracer.shutdown
      span = tracer.start_span('op', with_parent_context: context)
      span.context.trace_flags.wont_be :sampled?
      span.wont_be :recording_events?
      span.context.trace_id.must_equal(context.trace_id)
    end

    it 'creates a span with all supplied parameters' do
      links = [Link.new(span_context: context, attributes: nil)]
      name = 'span'
      kind = OpenTelemetry::Trace::SpanKind::INTERNAL
      attributes = { '1' => 1 }
      start_timestamp = Time.now
      span = tracer.start_span(name, with_parent_context: context, attributes: attributes, links: links, kind: kind, start_timestamp: start_timestamp)
      span.links.must_equal(links)
      span.name.must_equal(name)
      span.kind.must_equal(kind)
      span.attributes.must_equal(attributes)
      span.parent_span_id.must_equal(context.span_id)
      span.context.trace_id.must_equal(context.trace_id)
      span.start_timestamp.must_equal(start_timestamp)
    end

    it 'creates a span with sampler attributes added after supplied attributes' do
      sampler_attributes = { '1' => 1 }
      mock_sampler = Minitest::Mock.new
      result = Result.new(decision: Decision::RECORD, attributes: sampler_attributes)
      mock_sampler.expect(:call, result, [Hash])
      tracer.active_trace_config = TraceConfig.new(sampler: mock_sampler)
      span = tracer.start_span('op', with_parent_context: context, attributes: { '1' => 0, '2' => 2 })
      span.attributes.must_equal('1' => 1, '2' => 2)
    end

    it 'uses the context from parent span if supplied' do
      parent = tracer.start_root_span('root')
      span = tracer.start_span('child', with_parent: parent)
      span.parent_span_id.must_equal(parent.context.span_id)
      span.context.trace_id.must_equal(parent.context.trace_id)
    end

    it 'uses the implicit current span context by default' do
      root = nil
      span = nil
      tracer.in_span('root') do |s|
        root = s
        span = tracer.start_span('child')
      end
      span.parent_span_id.must_equal(root.context.span_id)
      span.context.trace_id.must_equal(root.context.trace_id)
    end
  end
end
