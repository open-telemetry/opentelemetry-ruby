# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Trace::Samplers::BasicDecision do
  describe '.sampled?' do
    it 'reflects decision when true' do
      decision = OpenTelemetry::Trace::Samplers::BasicDecision.new(
        decision: true
      )
      decision.sampled?.must_equal(true)
    end
    it 'reflects decision when false' do
      decision = OpenTelemetry::Trace::Samplers::BasicDecision.new(
        decision: false
      )
      decision.sampled?.must_equal(false)
    end
  end
  describe '.attributes' do
    it 'is empty' do
      decision = OpenTelemetry::Trace::Samplers::BasicDecision.new(
        decision: true
      )
      decision.attributes.must_equal({})
    end
  end
end
