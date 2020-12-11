# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::Result do
  Result = OpenTelemetry::SDK::Trace::Samplers::Result
  Decision = OpenTelemetry::SDK::Trace::Samplers::Decision

  describe '#attributes' do
    it 'is empty by default' do
      _(Result.new(decision: Decision::RECORD_ONLY, tracestate: nil).attributes).must_equal({})
    end

    it 'is an empty hash when initialized with nil' do
      _(Result.new(decision: Decision::RECORD_ONLY, attributes: nil, tracestate: nil).attributes).must_equal({})
    end

    it 'reflects values passed in' do
      attributes = {
        'foo' => 'bar',
        'bar' => 'baz'
      }
      _(Result.new(decision: Decision::RECORD_ONLY, attributes: attributes, tracestate: nil).attributes).must_equal(attributes)
    end

    it 'returns a frozen hash' do
      _(Result.new(decision: Decision::RECORD_ONLY, attributes: { 'foo' => 'bar' }, tracestate: nil).attributes).must_be(:frozen?)
    end

    it 'allows array-valued attributes' do
      attributes = { 'foo' => [1, 2, 3] }
      _(Result.new(decision: Decision::RECORD_ONLY, attributes: attributes, tracestate: nil).attributes).must_equal(attributes)
    end
  end

  describe '#tracestate' do
    it 'reflects the value passed in' do
      tracestate = Object.new
      _(Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate).tracestate).must_equal(tracestate)
    end
  end

  describe '#initialize' do
    it 'accepts Decision constants' do
      _(Result.new(decision: Decision::RECORD_ONLY, tracestate: nil)).wont_be_nil
      _(Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: nil)).wont_be_nil
      _(Result.new(decision: Decision::DROP, tracestate: nil)).wont_be_nil
    end

    it 'replaces invalid decisions with default' do
      _(Result.new(decision: nil, tracestate: nil)).wont_be_nil
      _(Result.new(decision: true, tracestate: nil)).wont_be_nil
      _(Result.new(decision: :ok, tracestate: nil)).wont_be_nil
    end
  end

  describe '#sampled?' do
    it 'returns true when decision is RECORD_AND_SAMPLE' do
      _(Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: nil)).must_be :sampled?
    end

    it 'returns false when decision is RECORD_ONLY' do
      _(Result.new(decision: Decision::RECORD_ONLY, tracestate: nil)).wont_be :sampled?
    end

    it 'returns false when decision is DROP' do
      _(Result.new(decision: Decision::DROP, tracestate: nil)).wont_be :sampled?
    end
  end

  describe '#recording?' do
    it 'returns true when decision is RECORD_AND_SAMPLE' do
      _(Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: nil)).must_be :recording?
    end

    it 'returns true when decision is RECORD_ONLY' do
      _(Result.new(decision: Decision::RECORD_ONLY, tracestate: nil)).must_be :recording?
    end

    it 'returns false when decision is DROP' do
      _(Result.new(decision: Decision::DROP, tracestate: nil)).wont_be :recording?
    end
  end
end
