# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Span do
  Span = OpenTelemetry::SDK::Trace::Span
  TraceConfig = OpenTelemetry::SDK::Trace::Config::TraceConfig
  NoopSpanProcessor = OpenTelemetry::SDK::Trace::NoopSpanProcessor
  SpanKind = OpenTelemetry::Trace::SpanKind
  Status = OpenTelemetry::Trace::Status

  let(:context) { OpenTelemetry::Trace::SpanContext.new }
  let(:span_processor) { NoopSpanProcessor.instance }
  let(:mock_span_processor) { Minitest::Mock.new }
  let(:trace_config) do
    TraceConfig.new(
      max_attributes_count: 1,
      max_events_count: 1,
      max_links_count: 1,
      max_attributes_per_event: 1,
      max_attributes_per_link: 1
    )
  end
  let(:span) do
    Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
             span_processor, nil, nil, Time.now, nil)
  end

  describe '#attributes' do
    it 'is frozen' do
      _(span.attributes).must_be :frozen?
    end
  end

  describe '#events' do
    it 'is frozen' do
      _(span.events).must_be :frozen?
    end
  end

  describe '#recording?' do
    it 'returns true' do
      _(span).must_be :recording?
    end
  end

  describe '#set_attribute' do
    it 'sets an attribute' do
      span.set_attribute('foo', 'bar')
      _(span.attributes).must_equal('foo' => 'bar')
    end

    it 'trims the oldest attribute' do
      span.set_attribute('old', 'oldbar')
      span.set_attribute('foo', 'bar')
      _(span.attributes).must_equal('foo' => 'bar')
    end

    it 'does not set an attribute if span is ended' do
      span.finish
      span.set_attribute('no', 'set')
      _(span.attributes).must_be_nil
    end

    it 'counts attributes' do
      span.set_attribute('old', 'oldbar')
      span.set_attribute('foo', 'bar')
      _(span.to_span_data.total_recorded_attributes).must_equal(2)
    end
  end

  describe '#add_event' do
    it 'add a named event' do
      span.add_event(name: 'added')
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.name).must_equal('added')
    end

    it 'add event with attributes' do
      attrs = { 'foo' => 'bar' }
      span.add_event(name: 'added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal(attrs)
    end

    it 'add event with timestamp' do
      ts = Time.now
      span.add_event(name: 'added', timestamp: ts)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.timestamp).must_equal(ts)
    end

    it 'add an event as event formatter' do
      span.add_event { OpenTelemetry::Trace::Event.new(name: 'c') }
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.name).must_equal('c')
    end

    it 'does not add an event if span is ended' do
      span.finish
      span.add_event(name: 'will_not_be_added')
      _(span.events).must_be_nil
    end

    it 'trims event attributes' do
      span.add_event(name: 'event', attributes: { '1' => 1, '2' => 2 })
      _(span.events.first.attributes.size).must_equal(1)
    end

    it 'counts events' do
      span.add_event(name: '1')
      span.add_event(name: '2')
      span.add_event(name: '3')
      _(span.to_span_data.total_recorded_events).must_equal(3)
    end

    it 'trims excess events' do
      span.add_event(name: '1')
      _(span.events.size).must_equal(1)
      span.add_event(name: '2')
      span.add_event(name: '3')
      _(span.events.size).must_equal(1)
    end
  end

  describe '#status=' do
    it 'sets the status' do
      span.status = Status.new(1, description: 'cancelled')
      _(span.status.description).must_equal('cancelled')
    end

    it 'does not set the status if span is ended' do
      span.finish
      span.status = Status.new(1, description: 'cancelled')
      _(span.status).must_be_nil
    end
  end

  describe '#name=' do
    it 'sets the name' do
      span.name = 'new_name'
      _(span.name).must_equal('new_name')
    end

    it 'does not set the name if span is ended' do
      span.finish
      span.name = 'new_name'
      _(span.name).must_equal('name')
    end
  end

  describe '#finish' do
    it 'returns itself' do
      _(span.finish).must_equal(span)
    end

    it 'sets the end timestamp' do
      span.finish
      _(span.to_span_data.end_timestamp).wont_be_nil
    end

    it 'calls the span processor #on_finish callback' do
      mock_span_processor.expect(:on_start, nil) { |_| true }
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      mock_span_processor, nil, nil, Time.now, nil)
      mock_span_processor.expect(:on_finish, nil, [span])
      span.finish
      mock_span_processor.verify
    end

    it 'marks the span as ended' do
      span.finish
      _(span.instance_variable_get(:@ended)).must_equal(true)
    end

    it 'does not allow ending more than once' do
      span.finish
      _(span.instance_variable_get(:@ended)).must_equal(true)
      ts = span.to_span_data.end_timestamp
      span.finish
      _(span.to_span_data.end_timestamp).must_equal(ts)
    end
  end

  describe '#initialize' do
    it 'installs the span processor' do
      _(span.instance_variable_get(:@span_processor)).must_equal(span_processor)
    end

    it 'calls the span processor #on_start callback' do
      yielded_span = nil
      mock_span_processor.expect(:on_start, nil) { |s| yielded_span = s }
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      mock_span_processor, nil, nil, Time.now, nil)
      _(yielded_span).must_equal(span)
      mock_span_processor.verify
    end

    it 'trims excess attributes' do
      attributes = { 'foo': 'bar', 'other': 'attr' }
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      span_processor, attributes, nil, Time.now, nil)
      _(span.to_span_data.total_recorded_attributes).must_equal(2)
      _(span.attributes.length).must_equal(1)
    end

    it 'counts attributes' do
      attributes = { 'foo': 'bar', 'other': 'attr' }
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      span_processor, attributes, nil, Time.now, nil)
      _(span.to_span_data.total_recorded_attributes).must_equal(2)
    end

    it 'counts links' do
      links = [OpenTelemetry::Trace::Link.new(context), OpenTelemetry::Trace::Link.new(context)]
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      span_processor, nil, links, Time.now, nil)
      _(span.to_span_data.total_recorded_links).must_equal(2)
    end

    it 'trims excess links' do
      links = [OpenTelemetry::Trace::Link.new(context), OpenTelemetry::Trace::Link.new(context)]
      span = Span.new(context, 'name', SpanKind::INTERNAL, nil, trace_config,
                      span_processor, nil, links, Time.now, nil)
      _(span.links.size).must_equal(1)
    end
  end
end
