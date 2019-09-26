# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Tracer do
  SpanContext = OpenTelemetry::Trace::SpanContext
  SpanContextBridge = OpenTelemetry::Bridge::OpenTracing::SpanContext
  let(:mock_tracer) { Minitest::Mock.new }
  let(:tracer_bridge) { OpenTelemetry::Bridge::OpenTracing::Tracer.new mock_tracer }
  describe '#active_span' do
    it 'gets the tracers active span' do
      mock_tracer.expect(:current_span, 'an_active_span')
      as = tracer_bridge.active_span
      as.must_equal 'an_active_span'
      mock_tracer.verify
    end
  end

  describe '#start_span' do
    it 'calls start span on the tracer' do
      args = ['name', { with_parent: 'parent', attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      mock_tracer.expect(:start_span, 'an_active_span', args)
      tracer_bridge.start_span('name', child_of: 'parent', references: 'refs', tags: 'tag', start_time: 'now')
      mock_tracer.verify
    end
  end

  describe '#start_active_span' do
    it 'calls start span on the tracer and with_span to make active' do
      args = ['name', { with_parent: 'parent', attributes: 'tag', links: 'refs', start_timestamp: 'now' }]
      mock_tracer.expect(:start_span, 'an_active_span', args)
      mock_tracer.expect(:with_span, nil, ['an_active_span'])
      tracer_bridge.start_active_span('name', child_of: 'parent', references: 'refs', tags: 'tag', start_time: 'now')
      mock_tracer.verify
    end
  end

  describe '#inject' do
    # TODO: leaving tbd as binary_format case needs to be worked out and needs to call super
    it 'requires a block' do
      span_context = SpanContextBridge.new SpanContext.new
      proc { tracer_bridge.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, {}) }.must_raise(ArgumentError)
    end

    it 'injects TEXT_MAP format as HTTP_TEXT_FORMAT' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      yielded = false
      carrier = {}
      tracer_bridge.inject(span_context, OpenTracing::FORMAT_TEXT_MAP, carrier) do |c, k, v|
        c.must_equal(carrier)
        k.must_equal('traceparent')
        v.must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      yielded.must_equal(true)
    end

    it 'injects RACK format as HTTP_TEXT_FORMAT' do
      context = SpanContext.new(trace_id: 'f' * 32, span_id: '1' * 16)
      span_context = SpanContextBridge.new context
      yielded = false
      carrier = {}
      tracer_bridge.inject(span_context, OpenTracing::FORMAT_RACK, carrier) do |c, k, v|
        c.must_equal(carrier)
        k.must_equal('traceparent')
        v.must_equal('00-ffffffffffffffffffffffffffffffff-1111111111111111-00')
        yielded = true
        c
      end
      yielded.must_equal(true)
    end

    it 'injects binary format onto the context' do
    end
  end

  describe '#extract' do
    it 'requires a block' do
      proc { tracer_bridge.extract(OpenTracing::FORMAT_TEXT_MAP, {}) }.must_raise(ArgumentError)
    end

    it 'extracts HTTP format from the context' do
      carrier = {}
      yielded = false
      tracer_bridge.extract(OpenTracing::FORMAT_TEXT_MAP, carrier) do |c, key|
        c.must_equal(carrier)
        key.must_equal('traceparent')
        yielded = true
        'a header'
      end
      yielded.must_equal(true)
    end

    it 'extracts rack format from the context' do
      carrier = {}
      yielded = false
      tracer_bridge.extract(OpenTracing::FORMAT_RACK, carrier) do |c, key|
        c.must_equal(carrier)
        key.must_equal('traceparent')
        yielded = true
        'a header'
      end
      yielded.must_equal(true)
    end

    it 'extracts binary format from the context' do
    end
  end
end
