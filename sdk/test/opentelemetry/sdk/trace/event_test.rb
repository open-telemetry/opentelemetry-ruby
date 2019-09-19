# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Event do
  Event = OpenTelemetry::SDK::Trace::Event
  describe '.new' do
    it 'accepts a name' do
      event = Event.new(name: 'message', attributes: nil, timestamp: nil)
      event.name.must_equal('message')
    end
  end
  describe '.attributes' do
    it 'returns an empty hash by default' do
      event = Event.new(name: 'message', attributes: nil, timestamp: nil)
      event.attributes.must_equal({})
    end

    it 'returns and freezes attributes passed in' do
      attributes = { 'message.id' => 123, 'message.type' => 'SENT' }
      event = Event.new(name: 'message', attributes: attributes, timestamp: nil)
      event.attributes.must_equal(attributes)
      event.attributes.must_be(:frozen?)
    end
  end
  describe '.timestamp' do
    it 'returns the timestamp passed in' do
      timestamp = Time.now
      event = Event.new(name: 'message', attributes: nil, timestamp: timestamp)
      event.timestamp.must_equal(timestamp)
    end
  end
end
