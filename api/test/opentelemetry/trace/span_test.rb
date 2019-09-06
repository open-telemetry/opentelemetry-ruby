# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Span do
  let(:span_context) do
    OpenTelemetry::Trace::SpanContext.new(trace_id: 123,
                                          span_id: 456,
                                          trace_options: 0x0)
  end
  let(:span) { build_span(span_context: span_context) }

  describe '#context' do
    it 'returns span context' do
      span.context.must_equal(span_context)
    end
  end

  describe '#recording_events?' do
    it 'returns false' do
      span.recording_events?.must_equal(false)
    end
  end

  describe '#set_attribute' do
    it 'returns self' do
      span.set_attribute('foo', 'bar').must_equal(span)
    end
  end

  describe '#add_event' do
    it 'returns self' do
      span.add_event('event-name').must_equal(span)
    end
  end

  describe '#finish' do
    it 'returns self' do
      span.finish.must_equal(span)
    end
  end

  describe '#add_link' do
    it 'accepts a span context' do
      span.add_link(span_context).must_equal(span)
    end
    it 'accepts a span context and attributes' do
      span.add_link(span_context, 'foo' => 'bar').must_equal(span)
    end
    it 'accepts a link formatter' do
      link_formatter =
        -> { OpenTelemetry::Trace::Link.new(span_context: span_context) }
      span.add_link(link_formatter).must_equal(span)
    end
    it 'raises if both attributes and formatter are passed in' do
      proc do
        link_formatter =
          -> { OpenTelemetry::Trace::Link.new(span_context: span_context) }
        span.add_link(link_formatter, 'foo' => 'bar')
      end.must_raise(ArgumentError)
    end
  end

  def build_span(*opts)
    OpenTelemetry::Trace::Span.new(*opts)
  end
end
