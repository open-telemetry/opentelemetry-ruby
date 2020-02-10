# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Tracer do
  SpanContext = OpenTelemetry::Trace::SpanContext
  SpanContextBridge = OpenTelemetry::Bridge::OpenTracing::SpanContext
  let(:tracer_mock) { Minitest::Mock.new }
  let(:tracer_bridge) { OpenTelemetry::Bridge::OpenTracing::Tracer.new tracer_mock }
  describe '#active_span' do
    it 'gets the active span' do
      scope_man = OpenTelemetry::Bridge::OpenTracing::ScopeManager.instance
      scope_mock = Minitest::Mock.new
      scope_mock.expect(:span, 'an_active_span')
      scope_man.active = scope_mock

      as = tracer_bridge.active_span
      as.must_equal 'an_active_span'
      scope_mock.verify
    end
  end

  describe '#start_span' do
    it 'calls start span on the tracer' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_bridge.start_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
    end

    it 'calls start span on the tracer when parent is OTrace Bridge span' do
      parent = OpenTelemetry::Bridge::OpenTracing::Span.new(OpenTelemetry::Trace::Span.new)
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent.span, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_bridge.start_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
    end

    it 'calls with_span if a block is given, yielding the span and returning the blocks value' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_mock.expect(:with_span, 'block_value', [to_be_wrapped])
      ret = tracer_bridge.start_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now') do |wrapped_span|
        wrapped_span.span.must_equal to_be_wrapped
        wrapped_span.context.context.must_equal to_be_wrapped.context
      end
      ret.must_equal 'block_value'
      tracer_mock.verify
    end

    it 'returns the span' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      span = tracer_bridge.start_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
      span.span.must_equal to_be_wrapped
      span.context.context.must_equal to_be_wrapped.context
    end
  end

  describe '#start_active_span' do
    it 'calls start span on the tracer and with_span to make active' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_bridge.start_active_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
    end

    it 'calls start span on the tracer and with_span to make active when parent is OTrace bridge span' do
      parent = OpenTelemetry::Bridge::OpenTracing::Span.new(OpenTelemetry::Trace::Span.new)
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent.span, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_bridge.start_active_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
    end

    it 'calls with_span if a block is given, yielding the scope and returning the blocks value' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      tracer_mock.expect(:with_span, 'block_value', [to_be_wrapped])
      ret = tracer_bridge.start_active_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now') do |scope|
        scope.span.span.must_equal to_be_wrapped
        scope.span.context.context.must_equal to_be_wrapped.context
      end
      ret.must_equal 'block_value'
      tracer_mock.verify
    end

    it 'returns a scope' do
      parent = OpenTelemetry::Trace::Span.new
      to_be_wrapped = OpenTelemetry::Trace::Span.new(span_context: 'foobar')
      args = ['name', { with_parent: parent, attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      tracer_mock.expect(:start_span, to_be_wrapped, args)
      scope = tracer_bridge.start_active_span('name', child_of: parent, references: 'refs', tags: 'tag', start_time: 'now')
      tracer_mock.verify
      scope.span.span.must_equal to_be_wrapped
      scope.span.context.context.must_equal to_be_wrapped.context
    end
  end

  describe '#inject' do
    it 'does nothing with unknown format' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      carrier = {}
      carried, key, value = tracer_bridge.inject(span_context, '4mat', carrier)
      carried.must_be_nil
      key.must_be_nil
      value.must_be_nil
    end

    it 'injects TEXT_MAP format as HTTP_TEXT_FORMAT' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      carrier = {}
      carried, key, value = tracer_bridge.inject(span_context, ::OpenTracing::FORMAT_TEXT_MAP, carrier)
      key.must_equal 'traceparent'
      value.must_equal '00-ffffffffffffffffffffffffffffffff-1111111111111111-00'
      carrier.must_equal carried
    end

    it 'injects RACK format as RACK_HTTP_TEXT_FORMAT' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      carrier = {}
      require 'byebug'
      byebug
      carried, key, value = tracer_bridge.inject(span_context, ::OpenTracing::FORMAT_RACK, carrier)
      key.must_equal 'HTTP_TRACEPARENT'
      value.must_equal '00-ffffffffffffffffffffffffffffffff-1111111111111111-00'
      carrier.must_equal carried
    end

    it 'injects BINARY format as BINARY_FORMAT' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      carrier = {}
      array = tracer_bridge.inject(span_context, ::OpenTracing::FORMAT_BINARY, carrier)
      array.must_equal []
    end
  end

  describe '#extract' do
    it 'does nothing with unknown format' do
      carrier = {}
      context = tracer_bridge.extract('4mat', carrier)
      context.must_be_nil
    end

    it 'extracts HTTP format from the context' do
      carrier = {}
      context = tracer_bridge.extract(::OpenTracing::FORMAT_TEXT_MAP, carrier)
      context.wont_be_nil
      context.must_be_instance_of OpenTelemetry::Context
    end

    it 'extracts rack format from the context' do
      carrier = {}
      context = tracer_bridge.extract(::OpenTracing::FORMAT_RACK, carrier)
      context.wont_be_nil
      context.must_be_instance_of OpenTelemetry::Context
    end

    it 'extracts binary format from the context' do
      carrier = {}
      context = tracer_bridge.extract(::OpenTracing::FORMAT_BINARY, carrier)
      context.wont_be_nil
      context.must_be_instance_of OpenTelemetry::Trace::SpanContext
      context.valid?.must_equal false
    end
  end
end
