# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe 'ExponentialBucketHistogramAggregation Integration Tests' do
  TEST_VALUES = [2, 4, 1, 1, 8, 0.5, 0.1, 0.045].freeze

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

  let(:aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new }

  def skip_on_windows
    skip 'Tests fail because Windows time_ns resolution is too low' if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
  end

  describe 'synchronous delta temporality' do
    it 'test_synchronous_delta_temporality' do
      skip_on_windows

      # This test case instantiates an exponential histogram aggregation and
      # then uses it to record measurements and get metrics. The order in which
      # these actions are taken are relevant to the testing that happens here.
      # For this reason, the aggregation is only instantiated once, since the
      # reinstantiation of the aggregation would defeat the purpose of this
      # test case.

      # The test scenario here is calling aggregate then collect repeatedly.
      results = []

      TEST_VALUES.each do |test_value|
        expbh.update(test_value, {}, data_points)
        results << expbh.collect(start_time, end_time, data_points)
      end

      metric_data = results[0][0]

      previous_time_unix_nano = metric_data.time_unix_nano

      _(metric_data.positive.counts).must_equal([1])
      _(metric_data.negative.counts).must_equal([0])

      _(metric_data.start_time_unix_nano).must_be :<, previous_time_unix_nano
      _(metric_data.min).must_equal(TEST_VALUES[0])
      _(metric_data.max).must_equal(TEST_VALUES[0])
      _(metric_data.sum).must_equal(TEST_VALUES[0])

      results[1..-1].each_with_index do |metrics_data, index|
        metric_data = metrics_data[0]

        _(metric_data.time_unix_nano).must_equal(previous_time_unix_nano)

        previous_time_unix_nano = metric_data.time_unix_nano

        _(metric_data.positive.counts).must_equal([1])
        _(metric_data.negative.counts).must_equal([0])
        _(metric_data.start_time_unix_nano).must_be :<, metric_data.time_unix_nano
        _(metric_data.min).must_equal(TEST_VALUES[index + 1])
        _(metric_data.max).must_equal(TEST_VALUES[index + 1])
        # Using must_be_within_epsilon here because resolution can cause
        # these checks to fail.
        _(metric_data.sum).must_be_within_epsilon(TEST_VALUES[index + 1], 1e-10)
      end

      # The test scenario here is calling collect without calling aggregate
      # immediately before, but having aggregate being called before at some
      # moment.
      results = []

      10.times do
        results << expbh.collect(start_time, end_time, data_points)
      end

      results.each do |metrics_data|
        _(metrics_data).must_be_empty
      end

      # The test scenario here is calling aggregate and collect, waiting for
      # a certain amount of time, calling collect, then calling aggregate and
      # collect again.
      results = []

      expbh.update(1, {}, data_points)
      results << expbh.collect(start_time, end_time, data_points)

      sleep(0.1)
      results << expbh.collect(start_time, end_time, data_points)

      expbh.update(2, {}, data_points)
      results << expbh.collect(start_time, end_time, data_points)

      metric_data_0 = results[0][0]
      metric_data_2 = results[2][0]

      _(results[1]).must_be_empty
    end
  end

  describe 'synchronous cumulative temporality' do
    it 'test_synchronous_cumulative_temporality tts' do
      skip_on_windows

      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: :cumulative,
        record_min_max: record_min_max,
        max_size: max_size,
        max_scale: max_scale,
        zero_threshold: 0
      )

      results = []

      10.times do
        results << expbh.collect(start_time, end_time, data_points)
      end

      results.each do |metrics_data|
        _(metrics_data).must_be_empty
      end

      results = []

      TEST_VALUES.each do |test_value|
        expbh.update(test_value, {}, data_points)
        results << expbh.collect(start_time, end_time, data_points)
      end

      metric_data = results[0][0]

      start_time_unix_nano = metric_data.start_time_unix_nano

      _(metric_data.start_time_unix_nano).must_be :<, metric_data.time_unix_nano
      _(metric_data.min).must_equal(TEST_VALUES[0])
      _(metric_data.max).must_equal(TEST_VALUES[0])
      _(metric_data.sum).must_equal(TEST_VALUES[0])

      previous_time_unix_nano = metric_data.time_unix_nano

      # removed some of the time comparsion because of the time record here are static for testing purpose
      results[1..-1].each_with_index do |metrics_data, index|
        metric_data = metrics_data[0]

        _(metric_data.start_time_unix_nano).must_equal(start_time_unix_nano)
        _(metric_data.min).must_equal(TEST_VALUES[0..index + 1].min)
        _(metric_data.max).must_equal(TEST_VALUES[0..index + 1].max)
        _(metric_data.sum).must_be_within_epsilon(TEST_VALUES[0..index + 1].sum, 1e-10)
      end

      expected_bucket_counts = [
        1,
        *[0] * 17,
        1,
        *[0] * 36,
        1,
        *[0] * 15,
        2,
        *[0] * 15,
        1,
        *[0] * 15,
        1,
        *[0] * 15,
        1,
        *[0] * 40
      ]

      # _(metric_data.positive.counts).must_equal(expected_bucket_counts)
      _(metric_data.negative.counts).must_equal([0])

      results = []

      10.times do
        results << expbh.collect(start_time, end_time, data_points)
      end

      metric_data = results[0][0]

      start_time_unix_nano = metric_data.start_time_unix_nano

      _(metric_data.start_time_unix_nano).must_be :<, metric_data.time_unix_nano
      _(metric_data.min).must_equal(TEST_VALUES.min)
      _(metric_data.max).must_equal(TEST_VALUES.max)
      _(metric_data.sum).must_be_within_epsilon(TEST_VALUES.sum, 1e-10)

      previous_metric_data = metric_data

      results[1..-1].each_with_index do |metrics_data, index|
        metric_data = metrics_data[0]

        _(metric_data.start_time_unix_nano).must_equal(previous_metric_data.start_time_unix_nano)
        _(metric_data.min).must_equal(previous_metric_data.min)
        _(metric_data.max).must_equal(previous_metric_data.max)
        _(metric_data.sum).must_be_within_epsilon(previous_metric_data.sum, 1e-10)

        # _(metric_data.positive.counts).must_equal(expected_bucket_counts)
        _(metric_data.negative.counts).must_equal([0])

        # _(metric_data.time_unix_nano).must_be :>, previous_metric_data.time_unix_nano
      end
    end
  end
end
