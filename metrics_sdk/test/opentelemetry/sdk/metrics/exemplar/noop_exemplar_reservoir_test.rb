# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::NoopExemplarReservoir do
  let(:reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::NoopExemplarReservoir.new }
  let(:context) do
    ::OpenTelemetry::Trace.context_with_span(
      ::OpenTelemetry::Trace.non_recording_span(
        ::OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array("w\xCBl\xCCR-1\x06\x11M\xD6\xEC\xBBp\x03j").pack('H*'),
          span_id: Array("1\xE1u\x12\x8E\xFC@\x18").pack('H*'),
          trace_flags: ::OpenTelemetry::Trace::TraceFlags::SAMPLED
        )
      )
    )
  end
  let(:timestamp) { 123_456_789 }
  let(:attributes) { { 'test' => 'value' } }

  describe '#offer' do
    it 'accepts all parameters without error' do
      reservoir.offer(value: 42, timestamp: timestamp, attributes: attributes, context: context)
    end

    it 'accepts nil parameters without error' do
      reservoir.offer(value: nil, timestamp: nil, attributes: nil, context: nil)
    end

    it 'accepts partial parameters without error' do
      reservoir.offer(value: 100)
    end
  end

  describe '#collect' do
    it 'returns an empty array' do
      result = reservoir.collect(attributes: attributes, aggregation_temporality: :delta)
      _(result).must_equal []
      _(result).must_be_instance_of Array
    end

    it 'returns empty array after offering values' do
      reservoir.offer(value: 42, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)

      result = reservoir.collect(attributes: attributes, aggregation_temporality: :delta)
      _(result).must_equal []
    end

    it 'returns empty array with cumulative temporality' do
      result = reservoir.collect(attributes: attributes, aggregation_temporality: :cumulative)
      _(result).must_equal []
    end

    it 'returns empty array with nil parameters' do
      result = reservoir.collect(attributes: nil, aggregation_temporality: nil)
      _(result).must_equal []
    end

    it 'returns empty array without parameters' do
      result = reservoir.collect
      _(result).must_equal []
    end
  end

  describe 'noop behavior' do
    it 'does not store or process exemplars' do
      # Offer multiple values
      10.times do |i|
        reservoir.offer(value: i, timestamp: timestamp + i, attributes: attributes, context: context)
      end

      # Collection should still return empty array
      result = reservoir.collect(attributes: attributes, aggregation_temporality: :delta)
      _(result).must_equal []
    end
  end
end
