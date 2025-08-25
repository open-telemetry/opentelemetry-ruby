# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram do
  let(:expbh) do
    OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
      aggregation_temporality: aggregation_temporality,
      record_min_max: record_min_max,
      max_size: max_size,
      max_scale: max_scale,
      zero_threshold: 0
    )
  end

  let(:data_points) { {} }
  let(:record_min_max) { true }
  let(:max_size) { 20 }
  let(:max_scale) { 5 }
  let(:aggregation_temporality) { :delta }
  # Time in nano
  let(:start_time) { Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond) }
  let(:end_time) { Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond) + (60 * 1_000_000_000) }
  let(:cardinality_limit) { 2000 }

  describe '#collect' do
    it 'returns all the data points' do
      expbh.update(1.03, {}, data_points, cardinality_limit)
      expbh.update(1.23, {}, data_points, cardinality_limit)
      expbh.update(0, {}, data_points, cardinality_limit)

      expbh.update(1.45, { 'foo' => 'bar' }, data_points, cardinality_limit)
      expbh.update(1.67, { 'foo' => 'bar' }, data_points, cardinality_limit)

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      _(exphdps.size).must_equal(2)
      _(exphdps[0].attributes).must_equal({})
      _(exphdps[0].count).must_equal(3)
      _(exphdps[0].sum).must_equal(2.26)
      _(exphdps[0].min).must_equal(0)
      _(exphdps[0].max).must_equal(1.23)
      _(exphdps[0].scale).must_equal(5)
      _(exphdps[0].zero_count).must_equal(1)
      _(exphdps[0].positive.counts).must_equal([1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0])
      _(exphdps[0].negative.counts).must_equal([0])
      _(exphdps[0].zero_threshold).must_equal(0)

      _(exphdps[1].attributes).must_equal('foo' => 'bar')
      _(exphdps[1].count).must_equal(2)
      _(exphdps[1].sum).must_equal(3.12)
      _(exphdps[1].min).must_equal(1.45)
      _(exphdps[1].max).must_equal(1.67)
      _(exphdps[1].scale).must_equal(5)
      _(exphdps[1].zero_count).must_equal(0)
      _(exphdps[1].positive.counts).must_equal([1, 0, 0, 0, 0, 0, 1, 0])
      _(exphdps[1].negative.counts).must_equal([0])
      _(exphdps[1].zero_threshold).must_equal(0)
    end

    it 'rescales with alternating growth 0' do
      # Tests insertion of [2, 4, 1]. The index of 2 (i.e., 0) becomes
      # `indexBase`, the 4 goes to its right and the 1 goes in the last
      # position of the backing array. With 3 binary orders of magnitude
      # and MaxSize=4, this must finish with scale=0; with minimum value 1
      # this must finish with offset=-1 (all scales).

      # The corresponding Go test is TestAlternatingGrowth1 where:
      # agg := NewFloat64(NewConfig(WithMaxSize(4)))
      # agg is an instance of (go package) github.com/lightstep/otel-launcher-go/lightstep/sdk/metric/aggregator/histogram/structure.Histogram[float64]
      # agg permalink: https://github.com/lightstep/otel-launcher-go/blob/v1.34.0/lightstep/sdk/metric/aggregator/histogram/histogram.go#L34
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: 4,
        max_scale: 20, # use default value of max scale; should downscale to 0
        zero_threshold: 0
      )

      expbh.update(2, {}, data_points, cardinality_limit)
      expbh.update(4, {}, data_points, cardinality_limit)
      expbh.update(1, {}, data_points, cardinality_limit)

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      _(exphdps.size).must_equal(1)
      _(exphdps[0].attributes).must_equal({})
      _(exphdps[0].count).must_equal(3)
      _(exphdps[0].sum).must_equal(7)
      _(exphdps[0].min).must_equal(1)
      _(exphdps[0].max).must_equal(4)
      _(exphdps[0].scale).must_equal(0)
      _(exphdps[0].zero_count).must_equal(0)
      _(exphdps[0].positive.offset).must_equal(-1)
      _(exphdps[0].positive.counts).must_equal([1, 1, 1, 0])
      _(exphdps[0].negative.counts).must_equal([0])
      _(exphdps[0].zero_threshold).must_equal(0)
    end

    it 'rescale_with_alternating_growth_1' do
      # Tests insertion of [2, 2, 4, 1, 8, 0.5].  The test proceeds as
      # above but then downscales once further to scale=-1, thus index -1
      # holds range [0.25, 1.0), index 0 holds range [1.0, 4), index 1
      # holds range [4, 16).
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: 4,
        max_scale: 20, # use default value of max scale; should downscale to 0
        zero_threshold: 0
      )

      expbh.update(2, {}, data_points, cardinality_limit)
      expbh.update(2, {}, data_points, cardinality_limit)
      expbh.update(2, {}, data_points, cardinality_limit)
      expbh.update(1, {}, data_points, cardinality_limit)
      expbh.update(8, {}, data_points, cardinality_limit)
      expbh.update(0.5, {}, data_points, cardinality_limit)

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      _(exphdps.size).must_equal(1)
      _(exphdps[0].attributes).must_equal({})
      _(exphdps[0].count).must_equal(6)
      _(exphdps[0].sum).must_equal(15.5)
      _(exphdps[0].min).must_equal(0.5)
      _(exphdps[0].max).must_equal(8)
      _(exphdps[0].scale).must_equal(-1)
      _(exphdps[0].zero_count).must_equal(0)
      _(exphdps[0].positive.offset).must_equal(-1)
      _(exphdps[0].positive.counts).must_equal([2, 3, 1, 0])
      _(exphdps[0].negative.counts).must_equal([0])
      _(exphdps[0].zero_threshold).must_equal(0)
    end

    it 'test_permutations' do
      test_cases = [
        [
          [0.5, 1.0, 2.0],
          {
            scale: -1,
            offset: -1,
            len: 2,
            at_zero: 2,
            at_one: 1
          }
        ],
        [
          [1.0, 2.0, 4.0],
          {
            scale: -1,
            offset: -1,
            len: 2,
            at_zero: 1,
            at_one: 2
          }
        ],
        [
          [0.25, 0.5, 1.0],
          {
            scale: -1,
            offset: -2,
            len: 2,
            at_zero: 1,
            at_one: 2
          }
        ]
      ]

      test_cases.each do |test_values, expected|
        test_values.permutation.each do |permutation|
          expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
            aggregation_temporality: aggregation_temporality,
            record_min_max: record_min_max,
            max_size: 2,
            max_scale: 20, # use default value of max scale; should downscale to 0
            zero_threshold: 0
          )

          permutation.each do |value|
            expbh.update(value, {}, data_points, cardinality_limit)
          end

          exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

          assert_equal expected[:scale], exphdps[0].scale
          assert_equal expected[:offset], exphdps[0].positive.offset
          assert_equal expected[:len], exphdps[0].positive.length
          assert_equal expected[:at_zero], exphdps[0].positive.counts[0]
          assert_equal expected[:at_one], exphdps[0].positive.counts[1]
        end
      end
    end

    it 'test_full_range' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: 2,
        max_scale: 20, # use default value of max scale; should downscale to 0
        zero_threshold: 0
      )

      expbh.update(Float::MAX, {}, data_points, cardinality_limit)
      expbh.update(1, {}, data_points, cardinality_limit)
      expbh.update(2**-1074, {}, data_points, cardinality_limit)

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      assert_equal Float::MAX, exphdps[0].sum
      assert_equal 3, exphdps[0].count
      assert_equal(-10, exphdps[0].scale)

      assert_equal 2, exphdps[0].positive.length
      assert_equal(-1, exphdps[0].positive.offset)
      assert_operator exphdps[0].positive.counts[0], :<=, 2
      assert_operator exphdps[0].positive.counts[1], :<=, 1
    end

    it 'test_aggregator_min_max' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      [1, 3, 5, 7, 9].each do |value|
        expbh.update(value, {}, data_points, cardinality_limit)
      end

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      assert_equal 1, exphdps[0].min
      assert_equal 9, exphdps[0].max

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      [-1, -3, -5, -7, -9].each do |value|
        expbh.update(value, {}, data_points, cardinality_limit)
      end

      exphdps = expbh.collect(start_time, end_time, data_points, cardinality_limit)

      assert_equal(-9, exphdps[0].min)
      assert_equal(-1, exphdps[0].max)
    end

    it 'test_merge' do
      # TODO
    end

    it 'test_invalid_scale_validation' do
      error = assert_raises(ArgumentError) do
        OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: 100)
      end
      assert_equal('Scale 100 is larger than maximum scale 20', error.message)

      error = assert_raises(ArgumentError) do
        OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: -20)
      end
      assert_equal('Scale -20 is smaller than minimum scale -10', error.message)
    end

    it 'test_invalid_size_validation' do
      error = assert_raises(ArgumentError) do
        OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_size: 10_000_000)
      end
      assert_equal('Max size 10000000 is larger than maximum size 16384', error.message)

      error = assert_raises(ArgumentError) do
        OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_size: 0)
      end
      assert_equal('Max size 0 is smaller than minimum size 2', error.message)
    end
  end
end
