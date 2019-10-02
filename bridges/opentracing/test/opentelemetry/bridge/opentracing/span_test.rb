# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Bridge::OpenTracing::Span do
  SpanBridge = OpenTelemetry::Bridge::OpenTracing::Span

  let(:span_mock) { Minitest::Mock.new }
  let(:dist_context_mock) { Minitest::Mock.new }
  let(:span_bridge) { SpanBridge.new(span_mock, dist_context: dist_context_mock) }
  describe '#operation_name=' do
    it 'sets the operation name on the underlying span' do
      span_mock.expect(:name=, nil, ['operation'])
      span_bridge.operation_name = 'operation'
      span_mock.verify
    end
  end

  describe '#set_tag' do
    it 'sets the tag as attribute on underlying span' do
      span_mock.expect(:set_attribute, nil, %w[k v])
      span_bridge.set_tag('k', 'v')
      span_mock.verify
    end
  end

  describe '#finish' do
    it 'sets end timestamp' do
      span_mock.expect :finish, nil do |_|
        true
      end
      span_bridge.finish
      span_mock.verify
    end

    it 'sets end timestamp passed in' do
      ts = Time.now
      span_mock.expect :finish, nil do |end_timestamp:|
        end_timestamp == ts
      end
      span_bridge.finish(end_time: ts)
      span_mock.verify
    end

    it 'returns itself' do
      span_mock.expect :finish, nil do |_|
        true
      end
      span_bridge.finish.must_equal(span_bridge)
      span_mock.verify
    end
  end

  describe '#log' do
    it 'adds the event to the span' do
      span_mock.expect :add_event, nil do |args|
        args[:name] == 'an_event' &&
          args[:attributes] == { foo: 'bar' }
      end
      span_bridge.log(event: 'an_event', foo: 'bar')
      span_mock.verify
    end

    it 'adds the event with a passed in timestamp' do
      ts = Time.now
      span_mock.expect :add_event, nil do |args|
        args[:name] == 'an_event' &&
          args[:timestamp] == ts &&
          args[:attributes] == { foo: 'bar' }
      end
      span_bridge.log(event: 'an_event', timestamp: ts, foo: 'bar')
      span_mock.verify
    end
  end

  describe '#log_kv' do
    it 'adds the event with the default name' do
      span_mock.expect :add_event, nil do |args|
        args[:name] == 'log' &&
          args[:attributes] == { foo: 'bar' }
      end
      span_bridge.log_kv(foo: 'bar')
      span_mock.verify
    end

    it 'adds the event with the name from fields' do
      span_mock.expect :add_event, nil do |args|
        args[:name] == 'not default' &&
          args[:attributes] == { event: 'not default', foo: 'bar' }
      end
      span_bridge.log_kv(event: 'not default', foo: 'bar')
      span_mock.verify
    end
  end

  describe '#set_baggage_item' do
    it 'does not call set baggage item with nil key' do
      span_bridge.set_baggage_item(nil, 'val')
      dist_context_mock.verify
    end

    it 'does not call set baggage item with nil value' do
      span_bridge.set_baggage_item('key', nil)
      dist_context_mock.verify
    end

    it 'calls set baggage with key and value' do
      dist_context_mock.expect(:[]=, nil, %w[key val])
      span_bridge.set_baggage_item('key', 'val')
      dist_context_mock.verify
    end
  end

  describe '#get_baggage_item' do
    it 'calls get baggage on the context' do
      dist_context_mock.expect(:[], 'val', %w[key])
      span_bridge.get_baggage_item('key').must_equal 'val'
      dist_context_mock.verify
    end
  end
end
