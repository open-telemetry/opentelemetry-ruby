# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir do
  let(:reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: max_size) }
  let(:max_size) { 4 }
  let(:context) do
    ::OpenTelemetry::Trace.context_with_span(
      ::OpenTelemetry::Trace.non_recording_span(
        ::OpenTelemetry::Trace::SpanContext.new(
          trace_id: Array("w\xCBl\xCCR-1\x06\x11M\xD6\xEC\xBBp\x03j").pack('H*'),
          span_id: Array("1\xE1u\x12\x8E\xFC@\x18").pack('H*'),
          trace_flags: ::OpenTelemetry::Trace::TraceFlags::DEFAULT
        )
      )
    )
  end
  let(:timestamp) { 123_456_789 }
  let(:attributes) { { 'key' => 'value' } }

  describe '#initialize' do
    it 'uses DEFAULT_SIZE when max_size is not provided' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
      10.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }
      exemplars = reservoir.collect
      _(exemplars.size).must_be :<=, 10
    end

    it 'respects the provided max_size' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 2)
      3.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }
      exemplars = reservoir.collect
      _(exemplars.size).must_equal 2
    end
  end

  describe '#offer' do
    it 'stores exemplars up to max_size' do
      max_size.times { |i| reservoir.offer(value: i, timestamp: timestamp + i, attributes: attributes, context: context) }
      exemplars = reservoir.collect
      _(exemplars.size).must_equal max_size
    end

    it 'uses reservoir sampling when exceeding max_size' do
      (max_size * 3).times { |i| reservoir.offer(value: i, timestamp: timestamp + i, attributes: attributes, context: context) }
      exemplars = reservoir.collect

      _(exemplars.size).must_equal max_size

      exemplars.each do |exemplar|
        _(exemplar).must_be_kind_of OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
        _(exemplar.value).must_be :>=, 0
        _(exemplar.value).must_be :<, max_size * 3
      end
    end

    it 'stores correct exemplar data' do
      test_value = 42
      test_timestamp = 987_654_321
      test_attributes = { 'test_key' => 'test_value', 'number' => 123 }

      reservoir.offer(value: test_value, timestamp: test_timestamp, attributes: test_attributes, context: context)
      exemplars = reservoir.collect

      _(exemplars.size).must_equal 1
      exemplar = exemplars[0]
      _(exemplar.value).must_equal test_value
      _(exemplar.time_unix_nano).must_equal test_timestamp
      _(span_id_hex(exemplar.span_id)).must_equal '11e2ec08'
      _(trace_id_hex(exemplar.trace_id)).must_equal '0b5cbd16166cb933'
    end

    it 'maintains uniform distribution with reservoir sampling' do
      max_size = 10
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: max_size)

      100.times { |i| reservoir.offer(value: i, timestamp: timestamp + i, attributes: attributes, context: context) }
      exemplars = reservoir.collect

      _(exemplars.size).must_equal max_size

      values = exemplars.map(&:value).sort
      range = values.max - values.min
      _(range).must_be :>, 20
    end
  end

  describe '#collect' do
    it 'returns empty array when no exemplars offered' do
      exemplars = reservoir.collect
      _(exemplars).must_equal []
    end

    it 'filters collected attributes already present on a point' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: { 'shared' => 'value', 'unique' => 'keep' }, context: context)

      exemplars = reservoir.collect(attributes: { 'shared' => 'value' })

      _(exemplars.size).must_equal 1
      _(exemplars.first.filtered_attributes).must_equal({ 'unique' => 'keep' })
    end

    it 'resets measurement counter for delta temporality' do
      max_size.times { |i| reservoir.offer(value: i, timestamp: timestamp, attributes: attributes, context: context) }

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars.size).must_equal max_size

      _(reservoir.collect(aggregation_temporality: :delta)).must_equal []

      reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = reservoir.collect
      _(exemplars[0].value).must_equal 100
    end

    it 'clears exemplars for cumulative temporality' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 2, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 2

      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 0
    end
  end
end
