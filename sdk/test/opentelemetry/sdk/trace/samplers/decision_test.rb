# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::Decision do
  Decision = OpenTelemetry::SDK::Trace::Samplers::Decision
  describe '.sampled?' do
    it 'reflects decision when true' do
      decision = Decision.new(
        decision: true
      )
      decision.sampled?.must_equal(true)
    end
    it 'reflects decision when false' do
      decision = Decision.new(
        decision: false
      )
      decision.sampled?.must_equal(false)
    end
  end
  describe '.attributes' do
    it 'is empty by default' do
      decision = Decision.new(
        decision: true
      )
      decision.attributes.must_equal({})
    end
    it 'is an empty hash when initialized with nil' do
      decision = Decision.new(
        decision: true,
        attributes: nil
      )
      decision.attributes.must_equal({})
    end
    it 'reflects values passed in' do
      attributes = {
        'foo' => 'bar',
        'bar' => 'baz'
      }
      decision = Decision.new(
        decision: true,
        attributes: attributes
      )
      decision.attributes.must_equal(attributes)
    end
    it 'returns a frozen hash' do
      decision = Decision.new(
        decision: true,
        attributes: { 'foo' => 'bar' }
      )
      decision.attributes.must_be(:frozen?)
    end
  end
end
