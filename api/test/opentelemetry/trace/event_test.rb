# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Event do
  Event = OpenTelemetry::Trace::Event
  describe '.new' do
    it 'accepts a name' do
      event = Event.new(name: 'message')
      event.name.must_equal('message')
    end

    it 'returns an event with the given name, attributes, timestamp' do
      ts = Time.now
      event = Event.new(name: 'event', attributes: { '1' => 1 }, timestamp: ts)
      event.attributes.must_equal('1' => 1)
      event.name.must_equal('event')
      event.timestamp.must_equal(ts)
    end

    it 'returns an event with no attributes by default' do
      event = Event.new(name: 'event')
      event.attributes.must_equal({})
    end

    it 'returns an event with a default timestamp' do
      event = Event.new(name: 'event')
      event.timestamp.wont_be_nil
    end
  end
  describe '.attributes' do
    it 'returns and freezes attributes passed in' do
      attributes = { 'message.id' => 123, 'message.type' => 'SENT' }
      event = Event.new(name: 'message', attributes: attributes)
      event.attributes.must_equal(attributes)
      event.attributes.must_be(:frozen?)
    end
  end
  describe '.timestamp' do
    it 'returns the timestamp passed in' do
      timestamp = Time.now
      event = Event.new(name: 'message', timestamp: timestamp)
      event.timestamp.must_equal(timestamp)
    end
  end
end
