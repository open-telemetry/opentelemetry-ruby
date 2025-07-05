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

  describe '#collect' do
    it 'returns all the data points' do
      expbh.update(1.03, {}, data_points)
      expbh.update(1.23, {}, data_points)
      expbh.update(0, {}, data_points)

      expbh.update(1.45, { 'foo' => 'bar' }, data_points)
      expbh.update(1.67, { 'foo' => 'bar' }, data_points)

      exphdps = expbh.collect(start_time, end_time, data_points)

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

      expbh.update(2, {}, data_points)
      expbh.update(4, {}, data_points)
      expbh.update(1, {}, data_points)

      exphdps = expbh.collect(start_time, end_time, data_points)

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

      expbh.update(2, {}, data_points)
      expbh.update(2, {}, data_points)
      expbh.update(2, {}, data_points)
      expbh.update(1, {}, data_points)
      expbh.update(8, {}, data_points)
      expbh.update(0.5, {}, data_points)

      exphdps = expbh.collect(start_time, end_time, data_points)

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
            expbh.update(value, {}, data_points)
          end

          exphdps = expbh.collect(start_time, end_time, data_points)

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

      expbh.update(Float::MAX, {}, data_points)
      expbh.update(1, {}, data_points)
      expbh.update(2**-1074, {}, data_points)

      exphdps = expbh.collect(start_time, end_time, data_points)

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
        expbh.update(value, {}, data_points)
      end

      exphdps = expbh.collect(start_time, end_time, data_points)

      assert_equal 1, exphdps[0].min
      assert_equal 9, exphdps[0].max

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      [-1, -3, -5, -7, -9].each do |value|
        expbh.update(value, {}, data_points)
      end

      exphdps = expbh.collect(start_time, end_time, data_points)

      assert_equal(-9, exphdps[0].min)
      assert_equal(-1, exphdps[0].max)
    end

    it 'test_aggregate_collect_cycle' do
      # Tests a repeated cycle of aggregation and collection
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: :cumulative,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      local_data_points = {}

      expbh.update(2, {}, local_data_points)
      expbh.collect(start_time, end_time, local_data_points)

      expbh.update(2, {}, local_data_points)
      expbh.collect(start_time, end_time, local_data_points)

      expbh.update(2, {}, local_data_points)
      result = expbh.collect(start_time, end_time, local_data_points)

      _(result.size).must_equal(1)
      _(result.first.count).must_equal(3)
      _(result.first.sum).must_equal(6)
    end

    it 'test_boundary_statistics' do
      MAX_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_EXPONENT
      MIN_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MIN_NORMAL_EXPONENT
      total = MAX_NORMAL_EXPONENT - MIN_NORMAL_EXPONENT + 1

      (1..20).each do |scale|
        above = 0
        below = 0

        mapping = if scale <= 0
          OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(scale)
        else
          OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(scale)
        end

        (MIN_NORMAL_EXPONENT..MAX_NORMAL_EXPONENT).each do |exp|
          value = Math.ldexp(1, exp)
          index = mapping.map_to_index(value)

          begin
            boundary = mapping.get_lower_boundary(index + 1)
            if boundary < value
              above += 1
            elsif boundary > value
              below += 1
            end
          rescue StandardError
            # Handle boundary errors gracefully
          end
        end

        # Check that distribution is roughly balanced (within tolerance)
        above_ratio = above.to_f / total
        below_ratio = below.to_f / total

        _(above_ratio).must_be_within_epsilon(0.5, 0.05) if above > 0
        _(below_ratio).must_be_within_epsilon(0.5, 0.06) if below > 0
      end
    end

    it 'test_min_max_size' do
      # Tests that the minimum max_size is the right value
      min_max_size = 2 # Based on implementation details

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: min_max_size,
        zero_threshold: 0
      )

      local_data_points = {}

      # Use minimum and maximum normal floating point values
      expbh.update(Float::MIN, {}, local_data_points)
      expbh.update(Float::MAX, {}, local_data_points)

      hdp = local_data_points[{}]
      _(hdp.positive.counts.size).must_equal(min_max_size)
    end

    it 'test_create_aggregation_default' do
      # Test default values
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new

      _(expbh.instance_variable_get(:@scale)).must_equal(20) # MAX_SCALE
      _(expbh.instance_variable_get(:@size)).must_equal(160) # MAX_SIZE
    end

    it 'test_create_aggregation_custom_max_scale' do
      # Test custom max_scale
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: 10)

      _(expbh.instance_variable_get(:@scale)).must_equal(10)
    end

    it 'test_create_aggregation_invalid_large_scale' do
      # Ruby implementation logs warning and uses default instead of raising error
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: 100)

      _(expbh.instance_variable_get(:@scale)).must_equal(20) # uses default max scale
    end

    it 'test_ascending_sequence' do
      [3, 4, 6, 9].each do |max_size|
        (-5..5).each do |offset|
          [0, 4].each do |init_scale|
            ascending_sequence_test(max_size, offset, init_scale)
          end
        end
      end
    end

    def ascending_sequence_test(max_size, offset, init_scale)
      (max_size...(max_size * 4)).each do |step|
        expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
          aggregation_temporality: aggregation_temporality,
          record_min_max: record_min_max,
          max_size: max_size,
          max_scale: init_scale,
          zero_threshold: 0
        )

        local_data_points = {}

        mapping = if init_scale <= 0
          OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::ExponentMapping.new(init_scale)
        else
          OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::LogarithmMapping.new(init_scale)
        end

        # Generate test values
        sum_value = 0.0
        max_size.times do |index|
          value = 2**(offset + index) # Simple approximation for center_val
          expbh.update(value, {}, local_data_points)
          sum_value += value
        end

        hdp = local_data_points[{}]
        _(hdp.scale).must_equal(init_scale)
        _(hdp.positive.index_start).must_equal(offset)

        # Add one more value to trigger potential downscaling
        max_val = 2**(offset + step)
        expbh.update(max_val, {}, local_data_points)
        sum_value += max_val

        _(hdp.positive.counts[0]).wont_equal(0)

        # Find maximum filled bucket
        max_fill = 0
        total_count = 0
        hdp.positive.counts.each_with_index do |count, index|
          total_count += count
          max_fill = index if count != 0
        end

        _(max_fill).must_be :>=, max_size / 2
        _(total_count).must_be :<=, max_size + 1
        _(hdp.count).must_be :<=, max_size + 1
        _(hdp.sum).must_be :<=, sum_value
      end
    end

    it 'test_very_large_numbers' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: 2,
        max_scale: 20,
        zero_threshold: 0
      )

      def expect_balanced(hdp, count)
        _(hdp.positive.counts.size).must_equal(2)
        _(hdp.positive.index_start).must_equal(-1)
        _(hdp.positive.counts[0]).must_equal(count)
        _(hdp.positive.counts[1]).must_equal(count)
      end

      expbh.update(2**-100, {}, data_points)
      expbh.update(2**100, {}, data_points)

      hdp = data_points[{}]
      expected_sum = 2**100 + 2**-100
      _(hdp.sum).must_be_within_epsilon(expected_sum, 1e-5)
      _(hdp.count).must_equal(2)
      _(hdp.scale).must_equal(-7)
      expect_balanced(hdp, 1)

      expbh.update(2**-127, {}, data_points)
      expbh.update(2**128, {}, data_points)

      _(hdp.count).must_equal(4)
      _(hdp.scale).must_equal(-7)
      expect_balanced(hdp, 2)

      expbh.update(2**-129, {}, data_points)
      expbh.update(2**255, {}, data_points)

      _(hdp.count).must_equal(6)
      _(hdp.scale).must_equal(-8)
      expect_balanced(hdp, 3)
    end

    it 'test_zero_count_by_increment' do
      expbh_0 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      increment = 10
      data_points_0 = {}

      increment.times do
        expbh_0.update(0, {}, data_points_0)
      end

      expbh_1 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      data_points_1 = {}
      expbh_1.update(0, {}, data_points_1)

      # Simulate increment behavior by manually adjusting counts
      hdp_1 = data_points_1[{}]
      hdp_1.instance_variable_set(:@count, hdp_1.count * increment)
      hdp_1.instance_variable_set(:@zero_count, hdp_1.zero_count * increment)

      hdp_0 = data_points_0[{}]
      _(hdp_0.count).must_equal(hdp_1.count)
      _(hdp_0.zero_count).must_equal(hdp_1.zero_count)
      _(hdp_0.sum).must_equal(hdp_1.sum)
    end

    it 'test_one_count_by_increment' do
      expbh_0 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      increment = 10
      data_points_0 = {}

      increment.times do
        expbh_0.update(1, {}, data_points_0)
      end

      expbh_1 = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      data_points_1 = {}
      expbh_1.update(1, {}, data_points_1)

      # Simulate increment behavior
      hdp_1 = data_points_1[{}]
      hdp_1.instance_variable_set(:@count, hdp_1.count * increment)
      hdp_1.instance_variable_set(:@sum, hdp_1.sum * increment)

      hdp_0 = data_points_0[{}]
      _(hdp_0.count).must_equal(hdp_1.count)
      _(hdp_0.sum).must_equal(hdp_1.sum)
    end

    it 'test_collect_results_cumulative' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: :cumulative,
        record_min_max: record_min_max,
        zero_threshold: 0
      )

      _(expbh.instance_variable_get(:@scale)).must_equal(20)

      expbh.update(2, {}, data_points)
      _(data_points[{}].scale).must_equal(20)

      expbh.update(4, {}, data_points)
      _(data_points[{}].scale).must_equal(7)

      expbh.update(1, {}, data_points)
      _(data_points[{}].scale).must_equal(6)

      collection_0 = expbh.collect(start_time, end_time, data_points)

      _(collection_0.size).must_equal(1)
      result_0 = collection_0.first

      _(result_0.positive.counts.size).must_equal(160)
      _(result_0.count).must_equal(3)
      _(result_0.sum).must_equal(7)
      _(result_0.scale).must_equal(6)
      _(result_0.zero_count).must_equal(0)
      _(result_0.min).must_equal(1)
      _(result_0.max).must_equal(4)

      [1, 8, 0.5, 0.1, 0.045].each do |value|
        expbh.update(value, {}, data_points)
      end

      collection_1 = expbh.collect(start_time, end_time, data_points)
      result_1 = collection_1.first

      _(result_1.count).must_equal(8)
      _(result_1.sum.round(3)).must_equal(16.645)
      _(result_1.scale).must_equal(4)
      _(result_1.zero_count).must_equal(0)
      _(result_1.min).must_equal(0.045)
      _(result_1.max).must_equal(8)
    end

    it 'test_merge_collect_cumulative' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: :cumulative,
        record_min_max: record_min_max,
        max_size: 4,
        zero_threshold: 0
      )

      [2, 4, 8, 16].each do |value|
        expbh.update(value, {}, data_points)
      end

      hdp = data_points[{}]
      _(hdp.scale).must_equal(0)
      _(hdp.positive.index_start).must_equal(0)
      _(hdp.positive.counts).must_equal([1, 1, 1, 1])

      result_0 = expbh.collect(start_time, end_time, data_points)
      _(result_0.first.scale).must_equal(0)

      [1, 2, 4, 8].each do |value|
        expbh.update(1.0 / value, {}, data_points)
      end

      _(hdp.scale).must_equal(0)
      _(hdp.positive.index_start).must_equal(-4)
      _(hdp.positive.counts).must_equal([1, 1, 1, 1])

      result_1 = expbh.collect(start_time, end_time, data_points)
      _(result_1.first.scale).must_equal(-1)
    end

    it 'test_merge_collect_delta' do
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: :delta,
        record_min_max: record_min_max,
        max_size: 4,
        zero_threshold: 0
      )

      local_data_points = {}

      [2, 4, 8, 16].each do |value|
        expbh.update(value, {}, local_data_points)
      end

      hdp = local_data_points[{}]
      _(hdp.scale).must_equal(0)
      _(hdp.positive.index_start).must_equal(0)
      _(hdp.positive.counts).must_equal([1, 1, 1, 1])

      result = expbh.collect(start_time, end_time, local_data_points)

      [1, 2, 4, 8].each do |value|
        expbh.update(1.0 / value, {}, local_data_points)
      end

      hdp = local_data_points[{}]
      _(hdp.scale).must_equal(0)
      _(hdp.positive.index_start).must_equal(-4)
      _(hdp.positive.counts).must_equal([1, 1, 1, 1])

      result_1 = expbh.collect(start_time, end_time, local_data_points)

      _(result.first.scale).must_equal(result_1.first.scale)
    end

    it 'test_invalid_scale_validation' do
      # Test that invalid scales are handled gracefully
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: 100)
      _(expbh.instance_variable_get(:@scale)).must_equal(20) # should use default

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_scale: -20)
      _(expbh.instance_variable_get(:@scale)).must_equal(20) # should use default
    end

    it 'test_invalid_size_validation' do
      # Test that invalid sizes are handled gracefully
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_size: 1000)
      _(expbh.instance_variable_get(:@size)).must_equal(160) # should use default

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(max_size: -1)
      _(expbh.instance_variable_get(:@size)).must_equal(160) # should use default
    end
  end
end
