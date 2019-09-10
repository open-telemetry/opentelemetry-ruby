# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::TimedEvent do
  TimedEvent = OpenTelemetry::SDK::Trace::TimedEvent
  it 'should use Time.now if no time is sent' do
    Time.stub(:now, 1000) do
      TimedEvent.new(name: 'foo').time.must_equal(1000)
    end
  end

  it 'should use an empty attributes if not set' do
    TimedEvent.new(name: 'foo').attributes.length.must_equal(0)
  end

  it 'should use the passed in time value if passed' do
    t = Time.new(1000)
    TimedEvent.new(name: 'foo', time: t).time.must_equal(t)
  end
end
