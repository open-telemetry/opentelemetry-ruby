# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Span do
  let(:span_context) do
    OpenTelemetry::Trace::SpanContext.new
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
      span.add_event(name: 'event-name').must_equal(span)
    end

    it 'accepts a name and attributes' do
      span.add_event(name: 'event-name', attributes: { 'foo' => 'bar' }).must_equal(span)
    end

    it 'accepts a timestamp' do
      span.add_event(name: 'event-name', timestamp: Time.now).must_equal(span)
    end

    it 'accepts an event formatter' do
      span.add_event { Object.new }.must_equal(span)
    end

    it 'raises if both attributes and formatter are passed in' do
      proc do
        span.add_event(attributes: { 'foo' => 'bar' }) { Object.new }
      end.must_raise(ArgumentError)
    end
  end

  describe '#finish' do
    it 'returns self' do
      span.finish.must_equal(span)
    end
  end

  def build_span(*opts)
    OpenTelemetry::Trace::Span.new(*opts)
  end
end
