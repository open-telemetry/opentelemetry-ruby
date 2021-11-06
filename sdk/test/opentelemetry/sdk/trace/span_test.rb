# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Span do
  Span = OpenTelemetry::SDK::Trace::Span
  SpanKind = OpenTelemetry::Trace::SpanKind
  Status = OpenTelemetry::Trace::Status
  Context = OpenTelemetry::Context

  let(:context) { OpenTelemetry::Trace::SpanContext.new }
  let(:mock_span_processor) { Minitest::Mock.new }
  let(:span_limits) do
    OpenTelemetry::SDK::Trace::SpanLimits.new(
      attribute_count_limit: 1,
      event_count_limit: 1,
      link_count_limit: 1,
      event_attribute_count_limit: 1,
      link_attribute_count_limit: 1,
      attribute_length_limit: 32
    )
  end
  let(:span) do
    Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
             [], nil, nil, Time.now, nil, nil)
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

    it 'returns false when span is finished' do
      span.finish
      _(span).wont_be :recording?
    end
  end

  describe '#set_attribute' do
    before do
      @log_stream = StringIO.new
      @_logger = OpenTelemetry.logger
      OpenTelemetry.logger = ::Logger.new(@log_stream)
    end

    after do
      OpenTelemetry.logger = @_logger
    end

    it 'sets an attribute' do
      span.set_attribute('foo', 'bar')
      _(span.attributes).must_equal('foo' => 'bar')
    end

    it 'trims the oldest attribute' do
      span.set_attribute('old', 'oldbar')
      span.set_attribute('foo', 'bar')
      _(span.attributes).must_equal('foo' => 'bar')
    end

    it 'truncates attribute value length based if configured' do
      span.set_attribute('foo', 'oldbaroldbaroldbaroldbaroldbaroldbar')
      _(span.attributes).must_equal('foo' => 'oldbaroldbaroldbaroldbaroldba...')
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

    it 'accepts an array value' do
      span.set_attribute('foo', [1, 2, 3])
      _(span.attributes).must_equal('foo' => [1, 2, 3])
    end

    it 'reports an error for an invalid value' do
      span.set_attribute('foo', :bar)
      span.finish
      _(@log_stream.string).must_match(/invalid span attribute value type Symbol for key 'foo' on span 'name'/)
    end

    it 'reports an error for an invalid key' do
      span.set_attribute(nil, 'bar')
      span.finish
      _(@log_stream.string).must_match(/invalid span attribute key type NilClass on span 'name'/)
    end
  end

  describe '#add_attributes' do
    it 'sets attributes' do
      span.add_attributes('foo' => 'bar')
      _(span.attributes).must_equal('foo' => 'bar')
    end

    it 'trims the oldest attributes' do
      span.add_attributes('old' => 'oldbar')
      span.add_attributes('foo' => 'bar', 'bar' => 'baz')
      _(span.attributes).must_equal('bar' => 'baz')
    end

    it 'truncates attribute value length based if configured' do
      span.set_attribute('foo', 'oldbaroldbaroldbaroldbaroldbaroldbar')
      _(span.attributes).must_equal('foo' => 'oldbaroldbaroldbaroldbaroldba...')
    end

    it 'does not set an attribute if span is ended' do
      span.finish
      span.add_attributes('no' => 'set')
      _(span.attributes).must_be_nil
    end

    it 'counts attributes' do
      span.add_attributes('old' => 'oldbar')
      span.add_attributes('foo' => 'bar', 'bar' => 'baz')
      _(span.to_span_data.total_recorded_attributes).must_equal(3)
    end

    it 'accepts an array value' do
      span.add_attributes('foo' => [1, 2, 3])
      _(span.attributes).must_equal('foo' => [1, 2, 3])
    end
  end

  describe '#add_event' do
    it 'add a named event' do
      span.add_event('added')
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.name).must_equal('added')
    end

    it 'add event with attributes' do
      attrs = { 'foo' => 'bar' }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal(attrs)
    end

    it 'accepts array-valued attributes' do
      attrs = { 'foo' => [1, 2, 3] }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal(attrs)
    end

    it 'does not accept array-valued attributes if any elements are invalid' do
      attrs = { 'foo' => [1, 2, :bar] }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal({})
    end

    it 'does not accept array-valued attributes if the elements are different types' do
      attrs = { 'foo' => [1, 2, 'bar'] }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal({})
    end

    it 'accepts array-valued attributes if the elements are true and false' do
      attrs = { 'foo' => [true, false] }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal(attrs)
    end

    it 'accepts array-valued attributes if the array is empty' do
      attrs = { 'foo' => [] }
      span.add_event('added', attributes: attrs)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.attributes).must_equal(attrs)
    end

    it 'add event with timestamp' do
      ts = Time.now
      span.add_event('added', timestamp: ts)
      events = span.events
      _(events.size).must_equal(1)
      _(events.first.timestamp).must_equal(exportable_timestamp(ts))
    end

    it 'does not add an event if span is ended' do
      span.finish
      span.add_event('will_not_be_added')
      _(span.events).must_be_nil
    end

    it 'trims event attributes' do
      span.add_event('event', attributes: { '1' => 1, '2' => 2 })
      _(span.events.first.attributes.size).must_equal(1)
    end

    it 'truncates event attributes values if configured' do
      span.add_event('event', attributes: { 'foo' => 'oldbaroldbaroldbaroldbaroldbaroldbar' })
      _(span.events.first.attributes['foo']).must_equal('oldbaroldbaroldbaroldbaroldba...')
    end

    it 'trims event attributes with array values' do
      span.add_event('event', attributes: { '1' => [1, 2], '2' => [3, 4] })
      _(span.events.first.attributes.size).must_equal(1)
    end

    it 'counts events' do
      span.add_event('1')
      span.add_event('2')
      span.add_event('3')
      _(span.to_span_data.total_recorded_events).must_equal(3)
    end

    it 'trims excess events' do
      span.add_event('1')
      _(span.events.size).must_equal(1)
      span.add_event('2')
      span.add_event('3')
      _(span.events.size).must_equal(1)
    end
  end

  describe '#record_exception' do
    let(:span_limits) do
      SpanLimits.new(
        attribute_count_limit: 10,
        event_count_limit: 5,
        event_attribute_count_limit: 10
      )
    end

    let(:error) do
      raise 'oops'
    rescue StandardError => e
      e
    end

    it 'records error as an event' do
      span.record_exception(error)
      events = span.events
      _(events.size).must_equal(1)

      ev = events[0]

      _(ev.name).must_equal('exception')
      _(ev.attributes['exception.type']).must_equal(error.class.to_s)
      _(ev.attributes['exception.message']).must_equal(error.message)
      _(ev.attributes['exception.stacktrace']).must_equal(error.full_message(highlight: false, order: :top))
    end

    it 'merges optional attributes' do
      span.record_exception(error, attributes: { 'exception.type' => 'foo', 'bar' => 'baz' })
      events = span.events
      _(events.size).must_equal(1)

      ev = events[0]

      _(ev.name).must_equal('exception')
      _(ev.attributes['exception.type']).must_equal('foo')
      _(ev.attributes['exception.message']).must_equal(error.message)
      _(ev.attributes['exception.stacktrace']).must_equal(error.full_message(highlight: false, order: :top))
      _(ev.attributes['bar']).must_equal('baz')
    end

    it 'encodes the stacktrace' do
      begin
        raise "\xC2".dup.force_encoding(::Encoding::ASCII_8BIT)
      rescue StandardError => e
        span.record_exception(e)
      end

      events = span.events
      _(events.size).must_equal(1)
      ev = events[0]

      _(ev.name).must_equal('exception')

      # If this raises here, it will also raise during encoding
      # at the time of export.
      ev.attributes['exception.stacktrace'].encode('UTF-8')
      _(ev.attributes['exception.stacktrace']).must_include('� (RuntimeError)')
    end

    it 'records multiple errors' do
      3.times { span.record_exception(error) }
      events = span.events
      _(events.size).must_equal(3)

      events.each do |ev|
        _(ev.attributes['exception.type']).must_equal(error.class.to_s)
        _(ev.attributes['exception.message']).must_equal(error.message)
        _(ev.attributes['exception.stacktrace']).must_equal(error.full_message(highlight: false, order: :top))
      end
    end
  end

  describe '#status=' do
    it 'sets the status' do
      span.status = Status.error('cancelled')
      _(span.status.description).must_equal('cancelled')
      _(span.status.code).must_equal(Status::ERROR)
    end

    it 'does not set the status if span is ended' do
      span.finish
      span.status = Status.error('cancelled')
      _(span.status.code).must_equal(Status::UNSET)
    end

    it 'does not set the status if asked to set to UNSET' do
      span.status = Status.error('cancelled')
      span.status = Status.unset('actually, maybe it is OK?')
      _(span.status.description).must_equal('cancelled')
      _(span.status.code).must_equal(Status::ERROR)
    end

    it 'does not override the status once set to OK' do
      span.status = Status.ok('nothing to see here')
      span.status = Status.error('cancelled')
      _(span.status.description).must_equal('nothing to see here')
      _(span.status.code).must_equal(Status::OK)
    end

    it 'allows overriding ERROR with OK' do
      span.status = Status.error('cancelled')
      span.status = Status.ok('nothing to see here')
      _(span.status.description).must_equal('nothing to see here')
      _(span.status.code).must_equal(Status::OK)
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
      span = Span.new(context, Context.empty,
                      'name', SpanKind::INTERNAL, nil, span_limits,
                      [mock_span_processor], nil, nil, Time.now, nil, nil)
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
    it 'calls the span processor #on_start callback' do
      yielded_span = nil
      mock_span_processor.expect(:on_start, nil) { |s| yielded_span = s }
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [mock_span_processor], nil, nil, Time.now, nil, nil)
      _(yielded_span).must_equal(span)
      mock_span_processor.verify
    end

    it 'trims excess attributes' do
      attributes = { 'foo': 'bar', 'other': 'attr' }
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], attributes, nil, Time.now, nil, nil)
      _(span.to_span_data.total_recorded_attributes).must_equal(2)
      _(span.attributes.length).must_equal(1)
    end

    it 'truncates attributes if configured' do
      attributes = { 'foo': 'oldbaroldbaroldbaroldbaroldbaroldbar' }
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], attributes, nil, Time.now, nil, nil)
      _(span.attributes[:foo]).must_equal('oldbaroldbaroldbaroldbaroldba...')
    end

    it 'counts attributes' do
      attributes = { 'foo': 'bar', 'other': 'attr' }
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], attributes, nil, Time.now, nil, nil)
      _(span.to_span_data.total_recorded_attributes).must_equal(2)
    end

    it 'counts links' do
      links = [OpenTelemetry::Trace::Link.new(context), OpenTelemetry::Trace::Link.new(context)]
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], nil, links, Time.now, nil, nil)
      _(span.to_span_data.total_recorded_links).must_equal(2)
    end

    it 'trims excess links' do
      links = [OpenTelemetry::Trace::Link.new(context), OpenTelemetry::Trace::Link.new(context)]
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], nil, links, Time.now, nil, nil)
      _(span.links.size).must_equal(1)
    end

    it 'prunes invalid links' do
      invalid_context = OpenTelemetry::Trace::SpanContext.new(trace_id: OpenTelemetry::Trace::INVALID_TRACE_ID)
      links = [OpenTelemetry::Trace::Link.new(context), OpenTelemetry::Trace::Link.new(invalid_context)]
      span = Span.new(context, Context.empty, 'name', SpanKind::INTERNAL, nil, span_limits,
                      [], nil, links, Time.now, nil, nil)
      _(span.links.size).must_equal(1)
    end
  end
end
