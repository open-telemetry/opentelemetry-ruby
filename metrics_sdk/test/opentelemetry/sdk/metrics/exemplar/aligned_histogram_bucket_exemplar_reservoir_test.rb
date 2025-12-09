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
      # Default boundaries: [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000]
      # So we have 11 buckets (10 boundaries + 1)
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
      # Should have 4 buckets: (-inf, 10], (10, 20], (20, 30], (30, +inf)
      _(exemplars.size).must_equal 4
    end
  end

  describe '#offer' do
    it 'places exemplars in correct buckets based on value' do
      # Boundaries: [0, 5, 10, 25, 50, 75, 100]
      # Buckets: (-inf, 0], (0, 5], (5, 10], (10, 25], (25, 50], (50, 75], (75, 100], (100, +inf)

      reservoir.offer(value: -5, timestamp: timestamp, attributes: { 'bucket' => 'negative' }, context: context)
      reservoir.offer(value: 3, timestamp: timestamp + 1, attributes: { 'bucket' => '0-5' }, context: context)
      reservoir.offer(value: 7, timestamp: timestamp + 2, attributes: { 'bucket' => '5-10' }, context: context)
      reservoir.offer(value: 15, timestamp: timestamp + 3, attributes: { 'bucket' => '10-25' }, context: context)
      reservoir.offer(value: 30, timestamp: timestamp + 4, attributes: { 'bucket' => '25-50' }, context: context)
      reservoir.offer(value: 60, timestamp: timestamp + 5, attributes: { 'bucket' => '50-75' }, context: context)
      reservoir.offer(value: 90, timestamp: timestamp + 6, attributes: { 'bucket' => '75-100' }, context: context)
      reservoir.offer(value: 150, timestamp: timestamp + 7, attributes: { 'bucket' => 'above-100' }, context: context)

      exemplars = reservoir.collect

      # Should have 8 exemplars, one per bucket
      _(exemplars.size).must_equal 8

      # Verify values are in correct ranges
      _(exemplars[0].value).must_equal(-5) # bucket 0: (-inf, 0]
      _(exemplars[0].attributes['bucket']).must_equal 'negative'

      _(exemplars[1].value).must_equal(3) # bucket 1: (0, 5]
      _(exemplars[1].attributes['bucket']).must_equal '0-5'

      _(exemplars[2].value).must_equal(7) # bucket 2: (5, 10]
      _(exemplars[2].attributes['bucket']).must_equal '5-10'

      _(exemplars[3].value).must_equal(15) # bucket 3: (10, 25]
      _(exemplars[3].attributes['bucket']).must_equal '10-25'

      _(exemplars[4].value).must_equal(30) # bucket 4: (25, 50]
      _(exemplars[4].attributes['bucket']).must_equal '25-50'

      _(exemplars[5].value).must_equal(60) # bucket 5: (50, 75]
      _(exemplars[5].attributes['bucket']).must_equal '50-75'

      _(exemplars[6].value).must_equal(90) # bucket 6: (75, 100]
      _(exemplars[6].attributes['bucket']).must_equal '75-100'

      _(exemplars[7].value).must_equal(150) # bucket 7: (100, +inf)
      _(exemplars[7].attributes['bucket']).must_equal 'above-100'
    end

    it 'handles boundary values correctly' do
      # Values exactly on boundaries should go to the bucket where boundary is the upper limit
      reservoir.offer(value: 0, timestamp: timestamp, attributes: { 'exact' => '0' }, context: context)
      reservoir.offer(value: 5, timestamp: timestamp + 1, attributes: { 'exact' => '5' }, context: context)
      reservoir.offer(value: 10, timestamp: timestamp + 2, attributes: { 'exact' => '10' }, context: context)

      exemplars = reservoir.collect

      # value 0 goes to bucket where 0 is upper bound: (-inf, 0]
      _(exemplars.find { |e| e.attributes['exact'] == '0' }.value).must_equal 0

      # value 5 goes to bucket where 5 is upper bound: (0, 5]
      _(exemplars.find { |e| e.attributes['exact'] == '5' }.value).must_equal 5

      # value 10 goes to bucket where 10 is upper bound: (5, 10]
      _(exemplars.find { |e| e.attributes['exact'] == '10' }.value).must_equal 10
    end

    it 'uses reservoir sampling within each bucket' do
      # Offer multiple values to the same bucket (0, 5]
      # With reservoir sampling, later values have a chance to replace earlier ones
      20.times { |i| reservoir.offer(value: 1 + (i * 0.1), timestamp: timestamp + i, attributes: { 'iteration' => i }, context: context) }

      exemplars = reservoir.collect

      # Should still have only one exemplar for this bucket
      bucket_1_exemplars = exemplars.select { |e| e.value > 0 && e.value <= 5 }
      _(bucket_1_exemplars.size).must_equal 1

      # The exemplar should be one of the offered values
      _(bucket_1_exemplars[0].value).must_be :>, 0
      _(bucket_1_exemplars[0].value).must_be :<=, 5
    end

    it 'stores one exemplar per bucket maximum' do
      # Offer many values across all buckets
      100.times do |i|
        value = i - 20 # Range from -20 to 79
        reservoir.offer(value: value, timestamp: timestamp + i, attributes: { 'value' => value }, context: context)
      end

      exemplars = reservoir.collect

      # Should have at most one exemplar per bucket (8 buckets total)
      _(exemplars.size).must_be :<=, 8

      # All exemplars should be unique buckets
      values = exemplars.map(&:value)
      values.each_with_index do |value, i|
        # Find which bucket this value belongs to
        bucket_index = boundaries.index { |b| b >= value } || boundaries.size

        # Ensure no other value in the same bucket
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

      _(exemplars[0].span_id).must_equal '11e2ec08'
      _(exemplars[0].trace_id).must_equal '0b5cbd16166cb933'
    end
  end

  describe '#collect' do
    it 'returns empty array when no exemplars offered' do
      exemplars = reservoir.collect
      _(exemplars).must_equal []
    end

    it 'returns only non-nil exemplars' do
      # Offer to only some buckets
      reservoir.offer(value: 3, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 15, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect

      # Should only return 2 exemplars, not all 8 buckets
      _(exemplars.size).must_equal 2
      _(exemplars.all? { |e| e.is_a?(OpenTelemetry::SDK::Metrics::Exemplar::Exemplar) }).must_equal true
    end

    it 'resets measurement counters for delta temporality' do
      # Fill bucket with first value
      reservoir.offer(value: 3, timestamp: timestamp, attributes: { 'first' => 'true' }, context: context)

      # Collect with delta
      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars[0].attributes['first']).must_equal 'true'

      # After delta collection, counter resets, so next offer should definitely be stored
      reservoir.offer(value: 4, timestamp: timestamp + 1, attributes: { 'second' => 'true' }, context: context)
      exemplars = reservoir.collect

      # Should get the second value since counter was reset
      _(exemplars[0].attributes['second']).must_equal 'true'
    end

    it 'does not reset measurement counters for cumulative temporality' do
      # Fill bucket with many values
      10.times { |i| reservoir.offer(value: 3, timestamp: timestamp + i, attributes: { 'iteration' => i }, context: context) }

      # Collect with cumulative
      reservoir.collect(aggregation_temporality: :cumulative)

      # Counter should not reset, so probability of replacement decreases
      # Offer one more value
      reservoir.offer(value: 3, timestamp: timestamp + 100, attributes: { 'iteration' => 100 }, context: context)

      # The reservoir should still maintain sampling with the running count
      exemplars = reservoir.collect
      _(exemplars.size).must_equal 1
    end

    it 'clears exemplars for delta temporality' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars.size).must_equal 2

      # Second collect should return empty
      exemplars = reservoir.collect(aggregation_temporality: :delta)
      _(exemplars).must_equal []
    end

    it 'does not clear exemplars for cumulative temporality' do
      reservoir.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      reservoir.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 2

      # Second collect should still return exemplars
      exemplars = reservoir.collect(aggregation_temporality: :cumulative)
      _(exemplars.size).must_equal 2
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
      _(exemplars[0].attributes['below']).must_equal 'true'
      _(exemplars[1].value).must_equal 15
      _(exemplars[1].attributes['above']).must_equal 'true'
    end

    it 'handles empty boundaries gracefully' do
      empty_boundary_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: [])

      # All values go to the single bucket
      empty_boundary_reservoir.offer(value: -100, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 0, timestamp: timestamp, attributes: attributes, context: context)
      empty_boundary_reservoir.offer(value: 100, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = empty_boundary_reservoir.collect

      # Should have only 1 exemplar (one bucket)
      _(exemplars.size).must_equal 1
    end
  end
end
