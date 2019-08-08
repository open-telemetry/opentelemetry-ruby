# frozen_string_literal: true

require 'test_helper'

describe OpenTelemetry::Trace::Span do
  let(:span_context) { Object.new }
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

  def build_span(*opts)
    OpenTelemetry::Trace::Span.new(*opts)
  end
end
