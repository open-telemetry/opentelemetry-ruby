# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Event do
  describe '.new' do
    it 'accepts a name' do
      event = OpenTelemetry::Trace::Event.new(name: 'message')
      event.name.must_equal('message')
    end
  end
  describe '.attributes' do
    it 'returns an empty hash by default' do
      event = OpenTelemetry::Trace::Event.new(name: 'message')
      event.attributes.must_equal({})
    end

    it 'returns and freezes attributes passed in' do
      attributes = { 'message.id' => 123, 'message.type' => 'SENT' }
      event = OpenTelemetry::Trace::Event.new(name: name,
                                              attributes: attributes)
      event.attributes.must_equal(attributes)
      event.attributes.must_be(:frozen?)
    end
  end
end
