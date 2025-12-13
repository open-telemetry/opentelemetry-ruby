# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir do
  let(:boundaries) { [0, 5, 10, 25, 50, 75, 100] }
  let(:reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: boundaries) }
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
    it 'uses default boundaries when not provided' do
      default_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new
      default_reservoir.offer(value: -1, timestamp: timestamp, attributes: attributes, context: context)
      default_reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      default_reservoir.offer(value: 6, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = default_reservoir.collect
      _(exemplars.size).must_be :>=, 3
    end

    it 'accepts custom boundaries' do
      custom_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [10, 20, 30])
      custom_reservoir.offer(value: 5, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 15, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 25, timestamp: timestamp, attributes: attributes, context: context)
      custom_reservoir.offer(value: 35, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = custom_reservoir.collect
      _(exemplars.size).must_equal 4
    end
  end

  describe '#offer' do
    it 'places exemplars in correct buckets based on value' do
      reservoir.offer(value: -5, timestamp: timestamp, attributes: { 'bucket' => 'negative' }, context: context)
      reservoir.offer(value: 3, timestamp: timestamp + 1, attributes: { 'bucket' => '0-5' }, context: context)
      reservoir.offer(value: 7, timestamp: timestamp + 2, attributes: { 'bucket' => '5-10' }, context: context)
      reservoir.offer(value: 15, timestamp: timestamp + 3, attributes: { 'bucket' => '10-25' }, context: context)
      reservoir.offer(value: 30, timestamp: timestamp + 4, attributes: { 'bucket' => '25-50' }, context: context)
      reservoir.offer(value: 60, timestamp: timestamp + 5, attributes: { 'bucket' => '50-75' }, context: context)
      reservoir.offer(value: 90, timestamp: timestamp + 6, attributes: { 'bucket' => '75-100' }, context: context)
      reservoir.offer(value: 150, timestamp: timestamp + 7, attributes: { 'bucket' => 'above-100' }, context: context)

      exemplars = reservoir.collect

      _(exemplars.size).must_equal 8
    end

    it 'handles boundary values correctly' do
      reservoir.offer(value: 0, timestamp: timestamp, attributes: { 'exact' => '0' }, context: context)
      reservoir.offer(value: 5, timestamp: timestamp + 1, attributes: { 'exact' => '5' }, context: context)
      reservoir.offer(value: 10, timestamp: timestamp + 2, attributes: { 'exact' => '10' }, context: context)

      exemplars = reservoir.collect
      _(exemplars.size).must_equal 3
      _(exemplars.map(&:value).sort).must_equal [0, 5, 10]
    end

    it 'uses reservoir sampling within each bucket' do
      20.times { |i| reservoir.offer(value: 1 + (i * 0.1), timestamp: timestamp + i, attributes: { 'iteration' => i }, context: context) }

      exemplars = reservoir.collect

      bucket_1_exemplars = exemplars.select { |e| e.value > 0 && e.value <= 5 }
      _(bucket_1_exemplars.size).must_equal 1

      _(bucket_1_exemplars[0].value).must_be :>, 0
      _(bucket_1_exemplars[0].value).must_be :<=, 5
    end

    it 'stores one exemplar per bucket maximum' do
      100.times do |i|
        value = i - 20
        reservoir.offer(value: value, timestamp: timestamp + i, attributes: { 'value' => value }, context: context)
      end

      exemplars = reservoir.collect

      _(exemplars.size).must_be :<=, 8

      values = exemplars.map(&:value)
      values.each_with_index do |value, i|
        bucket_index = boundaries.index { |b| b >= value } || boundaries.size

        other_values = values[0...i] + values[(i + 1)..]
        other_values.each do |other_value|
          other_bucket_index = boundaries.index { |b| b >= other_value } || boundaries.size
          _(bucket_index).wont_equal other_bucket_index if value != other_value
        end
      end
    end

    it 'stores correct span context information' do
      reservoir.offer(value: 3, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = reservoir.collect

      _(span_id_hex(exemplars[0].span_id)).must_equal '11e2ec08'
      _(trace_id_hex(exemplars[0].trace_id)).must_equal '0b5cbd16166cb933'
    end
  end

  describe '#collect' do
    it 'returns empty array when no exemplars offered' do
      exemplars = reservoir.collect
      _(exemplars).must_equal []
    end

    it 'filters collected attributes already present on a point' do
      reservoir.offer(value: 3, timestamp: timestamp, attributes: { 'shared' => 'value', 'bucket' => 'keep' }, context: context)

      exemplars = reservoir.collect(attributes: { 'shared' => 'value' })

      _(exemplars.size).must_equal 1
      _(exemplars.first.filtered_attributes).must_equal({ 'bucket' => 'keep' })
    end

    it 'returns only non-nil exemplars' do
      reservoir.offer(value: 3, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 15, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect

      _(exemplars.size).must_equal 2
      _(exemplars.all? { |e| e.is_a?(OpenTelemetry::SDK::Metrics::Exemplar::Exemplar) }).must_equal true
    end

    it 'clears exemplars for delta temporality' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars.size).must_equal 2

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars).must_equal []
    end

    it 'clears exemplars for cumulative temporality' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 2

      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 0
    end
  end

  describe 'edge cases' do
    it 'handles single boundary correctly' do
      single_boundary_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [10])

      single_boundary_reservoir.offer(value: 5, timestamp: timestamp, attributes: { 'below' => 'true' }, context: context)
      single_boundary_reservoir.offer(value: 15, timestamp: timestamp, attributes: { 'above' => 'true' }, context: context)

      exemplars = single_boundary_reservoir.collect

      _(exemplars.size).must_equal 2
      _(exemplars[0].value).must_equal 5
      _(exemplars[1].value).must_equal 15
    end

    it 'handles empty boundaries gracefully' do
      empty_boundary_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [])

      empty_boundary_reservoir.offer(value: -100, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 0, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = empty_boundary_reservoir.collect

      _(exemplars.size).must_equal 1
    end
  end
end
