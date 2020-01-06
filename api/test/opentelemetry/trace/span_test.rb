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
      _(span.context).must_equal(span_context)
    end
  end

  describe '#recording?' do
    it 'returns false' do
      _(span.recording?).must_equal(false)
    end
  end

  describe '#set_attribute' do
    it 'returns self' do
      _(span.set_attribute('foo', 'bar')).must_equal(span)
    end
  end

  describe '#add_event' do
    it 'returns self' do
      _(span.add_event(name: 'event-name')).must_equal(span)
    end

    it 'accepts a name and attributes' do
      _(span.add_event(name: 'event-name', attributes: { 'foo' => 'bar' })).must_equal(span)
    end

    it 'accepts a timestamp' do
      _(span.add_event(name: 'event-name', timestamp: Time.now)).must_equal(span)
    end

    it 'accepts an event formatter' do
      _(span.add_event { Object.new }).must_equal(span)
    end
  end

  describe '#finish' do
    it 'returns self' do
      _(span.finish).must_equal(span)
    end
  end

  def build_span(**opts)
    OpenTelemetry::Trace::Span.new(**opts)
  end
end
