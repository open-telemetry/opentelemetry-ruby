# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Trace::Samplers::Result do
  Result = OpenTelemetry::SDK::Trace::Samplers::Result
  Decision = OpenTelemetry::SDK::Trace::Samplers::Decision

  describe '#attributes' do
    it 'is empty by default' do
      Result.new(decision: Decision::RECORD).attributes.must_equal({})
    end

    it 'is an empty hash when initialized with nil' do
      Result.new(decision: Decision::RECORD, attributes: nil).attributes.must_equal({})
    end

    it 'reflects values passed in' do
      attributes = {
        'foo' => 'bar',
        'bar' => 'baz'
      }
      Result.new(decision: Decision::RECORD, attributes: attributes).attributes.must_equal(attributes)
    end

    it 'returns a frozen hash' do
      Result.new(decision: Decision::RECORD, attributes: { 'foo' => 'bar' }).attributes.must_be(:frozen?)
    end
  end

  describe '#initialize' do
    it 'accepts Decision constants' do
      Result.new(decision: Decision::RECORD).wont_be_nil
      Result.new(decision: Decision::RECORD_AND_SAMPLED).wont_be_nil
      Result.new(decision: Decision::NOT_RECORD).wont_be_nil
    end

    it 'replaces invalid decisions with default' do
      _(Result.new(decision: nil)).wont_be_nil
      _(Result.new(decision: true)).wont_be_nil
      _(Result.new(decision: :ok)).wont_be_nil
    end
  end

  describe '#sampled?' do
    it 'returns true when decision is RECORD_AND_SAMPLED' do
      Result.new(decision: Decision::RECORD_AND_SAMPLED).must_be :sampled?
    end

    it 'returns false when decision is RECORD' do
      Result.new(decision: Decision::RECORD).wont_be :sampled?
    end

    it 'returns false when decision is NOT_RECORD' do
      Result.new(decision: Decision::NOT_RECORD).wont_be :sampled?
    end
  end

  describe '#recording?' do
    it 'returns true when decision is RECORD_AND_SAMPLED' do
      Result.new(decision: Decision::RECORD_AND_SAMPLED).must_be :recording?
    end

    it 'returns true when decision is RECORD' do
      Result.new(decision: Decision::RECORD).must_be :recording?
    end

    it 'returns false when decision is NOT_RECORD' do
      Result.new(decision: Decision::NOT_RECORD).wont_be :recording?
    end
  end
end
