# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram do
  let(:data_points) { {} }
  let(:ebh) do
    OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(
      aggregation_temporality:,
      boundaries:,
      record_min_max:
    )
  end
  let(:boundaries) { [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000] }
  let(:record_min_max) { true }
  let(:aggregation_temporality) { :delta }
  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }
  let(:cardinality_limit) { 2000 }

  describe '#initialize' do
    it 'defaults to the delta aggregation temporality' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'sets parameters from the environment to cumulative' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
        OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'sets parameters from the environment to delta' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'delta') do
        OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new
      end
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'sets parameters from the environment and converts them to symbols' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'potato') do
        OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'invalid aggregation_temporality from parameters return default to cumulative' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: 'pickles')
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'valid aggregation_temporality delta from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: 'delta')
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality cumulative from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: 'cumulative')
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'valid aggregation_temporality delta as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: :delta)
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality cumulative as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: :cumulative)
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'prefers explicit parameters rather than the environment and converts them to symbols' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'potato') do
        OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: 'pickles')
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'function arguments have higher priority than environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
        OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(aggregation_temporality: :delta)
      end
      _(exp.aggregation_temporality).must_equal :delta
    end
  end

  describe '#collect' do
    it 'returns all the data points' do
      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(1, {}, data_points, cardinality_limit)
      ebh.update(5, {}, data_points, cardinality_limit)
      ebh.update(6, {}, data_points, cardinality_limit)
      ebh.update(10, {}, data_points, cardinality_limit)

      ebh.update(-10, { 'foo' => 'bar' }, data_points, cardinality_limit)
      ebh.update(1, { 'foo' => 'bar' }, data_points, cardinality_limit)
      ebh.update(22, { 'foo' => 'bar' }, data_points, cardinality_limit)
      ebh.update(55, { 'foo' => 'bar' }, data_points, cardinality_limit)
      ebh.update(80, { 'foo' => 'bar' }, data_points, cardinality_limit)

      hdps = ebh.collect(start_time, end_time, data_points)
      _(hdps.size).must_equal(2)
      _(hdps[0].attributes).must_equal({})
      _(hdps[0].count).must_equal(5)
      _(hdps[0].sum).must_equal(22)
      _(hdps[0].min).must_equal(0)
      _(hdps[0].max).must_equal(10)
      _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])
      _(hdps[0].explicit_bounds).must_equal([0, 5, 10, 25, 50, 75, 100, 250, 500, 1000])

      _(hdps[1].attributes).must_equal('foo' => 'bar')
      _(hdps[1].count).must_equal(5)
      _(hdps[1].sum).must_equal(148)
      _(hdps[1].min).must_equal(-10)
      _(hdps[1].max).must_equal(80)
      _(hdps[1].bucket_counts).must_equal([1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0])
      _(hdps[1].explicit_bounds).must_equal([0, 5, 10, 25, 50, 75, 100, 250, 500, 1000])
    end

    it 'sets the timestamps' do
      ebh.update(0, {}, data_points, cardinality_limit)
      hdp = ebh.collect(start_time, end_time, data_points)[0]
      _(hdp.start_time_unix_nano).must_equal(start_time)
      _(hdp.time_unix_nano).must_equal(end_time)
    end

    it 'calculates the count' do
      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(0, {}, data_points, cardinality_limit)
      hdp = ebh.collect(start_time, end_time, data_points)[0]
      _(hdp.count).must_equal(4)
    end

    it 'does not aggregate between collects with default delta aggregation' do
      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(1, {}, data_points, cardinality_limit)
      ebh.update(5, {}, data_points, cardinality_limit)
      ebh.update(6, {}, data_points, cardinality_limit)
      ebh.update(10, {}, data_points, cardinality_limit)
      hdps = ebh.collect(start_time, end_time, data_points)

      ebh.update(0, {}, data_points, cardinality_limit)
      ebh.update(1, {}, data_points, cardinality_limit)
      ebh.update(5, {}, data_points, cardinality_limit)
      ebh.update(6, {}, data_points, cardinality_limit)
      ebh.update(10, {}, data_points, cardinality_limit)
      # Assert that the recent update does not
      # impact the already collected metrics
      _(hdps[0].count).must_equal(5)
      _(hdps[0].sum).must_equal(22)
      _(hdps[0].min).must_equal(0)
      _(hdps[0].max).must_equal(10)
      _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])

      hdps = ebh.collect(start_time, end_time, data_points)
      # Assert that we are not accumulating values
      # between calls to collect
      _(hdps[0].count).must_equal(5)
      _(hdps[0].sum).must_equal(22)
      _(hdps[0].min).must_equal(0)
      _(hdps[0].max).must_equal(10)
      _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])
    end

    describe 'when aggregation_temporality is not delta' do
      let(:aggregation_temporality) { :not_delta }

      it 'allows metrics to accumulate' do
        ebh.update(0, {}, data_points, cardinality_limit)
        ebh.update(1, {}, data_points, cardinality_limit)
        ebh.update(5, {}, data_points, cardinality_limit)
        ebh.update(6, {}, data_points, cardinality_limit)
        ebh.update(10, {}, data_points, cardinality_limit)
        hdps = ebh.collect(start_time, end_time, data_points)

        ebh.update(0, {}, data_points, cardinality_limit)
        ebh.update(1, {}, data_points, cardinality_limit)
        ebh.update(5, {}, data_points, cardinality_limit)
        ebh.update(6, {}, data_points, cardinality_limit)
        ebh.update(10, {}, data_points, cardinality_limit)
        # Assert that the recent update does not
        # impact the already collected metrics
        _(hdps[0].count).must_equal(5)
        _(hdps[0].sum).must_equal(22)
        _(hdps[0].min).must_equal(0)
        _(hdps[0].max).must_equal(10)
        _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])

        hdps1 = ebh.collect(start_time, end_time, data_points)
        # Assert that we are accumulating values
        # and not just capturing the delta since
        # the previous collect call
        _(hdps1[0].count).must_equal(10)
        _(hdps1[0].sum).must_equal(44)
        _(hdps1[0].min).must_equal(0)
        _(hdps1[0].max).must_equal(10)
        _(hdps1[0].bucket_counts).must_equal([2, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0])

        # Assert that the recent collect does not
        # impact the already collected metrics
        _(hdps[0].count).must_equal(5)
        _(hdps[0].sum).must_equal(22)
        _(hdps[0].min).must_equal(0)
        _(hdps[0].max).must_equal(10)
        _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])
      end
    end
  end

  describe '#update' do
    it 'accumulates across the default boundaries' do
      ebh.update(0, {}, data_points, cardinality_limit)

      ebh.update(1, {}, data_points, cardinality_limit)
      ebh.update(5, {}, data_points, cardinality_limit)

      ebh.update(6, {}, data_points, cardinality_limit)
      ebh.update(10, {}, data_points, cardinality_limit)

      ebh.update(11, {}, data_points, cardinality_limit)
      ebh.update(25, {}, data_points, cardinality_limit)

      ebh.update(26, {}, data_points, cardinality_limit)
      ebh.update(50, {}, data_points, cardinality_limit)

      ebh.update(51, {}, data_points, cardinality_limit)
      ebh.update(75, {}, data_points, cardinality_limit)

      ebh.update(76, {}, data_points, cardinality_limit)
      ebh.update(100, {}, data_points, cardinality_limit)

      ebh.update(101, {}, data_points, cardinality_limit)
      ebh.update(250, {}, data_points, cardinality_limit)

      ebh.update(251, {}, data_points, cardinality_limit)
      ebh.update(500, {}, data_points, cardinality_limit)

      ebh.update(501, {}, data_points, cardinality_limit)
      ebh.update(1000, {}, data_points, cardinality_limit)

      ebh.update(1001, {}, data_points, cardinality_limit)

      hdp = ebh.collect(start_time, end_time, data_points)[0]
      _(hdp.bucket_counts).must_equal([1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1])
      _(hdp.sum).must_equal(4040)
      _(hdp.min).must_equal(0)
      _(hdp.max).must_equal(1001)
    end

    describe 'with an unsorted boundary set' do
      let(:boundaries) { [4, 2, 1] }

      it 'sorts it' do
        ebh.update(0, {}, data_points, cardinality_limit)
        _(ebh.collect(start_time, end_time, data_points)[0].explicit_bounds).must_equal([1, 2, 4])
      end
    end

    describe 'with recording min max disabled' do
      let(:record_min_max) { false }

      it 'does not record min max values' do
        ebh.update(-1, {}, data_points, cardinality_limit)
        hdp = ebh.collect(start_time, end_time, data_points)[0]
        _(hdp.min).must_be_nil
        _(hdp.min).must_be_nil
      end
    end

    describe 'with custom boundaries' do
      let(:boundaries) { [0, 2, 4] }

      it 'aggregates' do
        ebh.update(-1, {}, data_points, cardinality_limit)
        ebh.update(0, {}, data_points, cardinality_limit)
        ebh.update(1, {}, data_points, cardinality_limit)
        ebh.update(2, {}, data_points, cardinality_limit)
        ebh.update(3, {}, data_points, cardinality_limit)
        ebh.update(4, {}, data_points, cardinality_limit)
        ebh.update(5, {}, data_points, cardinality_limit)
        hdp = ebh.collect(start_time, end_time, data_points)[0]

        _(hdp.bucket_counts).must_equal([2, 2, 2, 1])
      end
    end

    describe 'with a single boundary value' do
      let(:boundaries) { [0] }

      it 'aggregates' do
        ebh.update(-1, {}, data_points, cardinality_limit)
        ebh.update(1, {}, data_points, cardinality_limit)
        hdp = ebh.collect(start_time, end_time, data_points)[0]

        _(hdp.bucket_counts).must_equal([1, 1])
      end
    end

    describe 'with an empty boundary value' do
      let(:boundaries) { [] }

      it 'aggregates but does not record bucket counts' do
        ebh.update(-1, {}, data_points, cardinality_limit)
        ebh.update(3, {}, data_points, cardinality_limit)
        hdp = ebh.collect(start_time, end_time, data_points)[0]

        _(hdp.bucket_counts).must_be_nil
        _(hdp.explicit_bounds).must_be_nil
        _(hdp.sum).must_equal(2)
        _(hdp.count).must_equal(2)
        _(hdp.min).must_equal(-1)
        _(hdp.max).must_equal(3)
      end
    end

    describe 'with a nil boundary value' do
      let(:boundaries) { nil }

      it 'aggregates but does not record bucket counts' do
        ebh.update(-1, {}, data_points, cardinality_limit)
        ebh.update(3, {}, data_points, cardinality_limit)
        hdp = ebh.collect(start_time, end_time, data_points)[0]

        _(hdp.bucket_counts).must_be_nil
        _(hdp.explicit_bounds).must_be_nil
        _(hdp.sum).must_equal(2)
        _(hdp.count).must_equal(2)
        _(hdp.min).must_equal(-1)
        _(hdp.max).must_equal(3)
      end
    end
  end

  describe 'cardinality limit' do
    it 'handles overflow scenarios and merges measurements correctly' do
      cardinality_limit = 2
      # Test basic overflow behavior and multiple overflow merging in one flow
      ebh.update(1, { 'key' => 'a' }, data_points, cardinality_limit)
      ebh.update(5, { 'key' => 'b' }, data_points, cardinality_limit)
      ebh.update(10, { 'key' => 'c' }, data_points, cardinality_limit) # This should overflow
      ebh.update(15, { 'key' => 'd' }, data_points, cardinality_limit) # Also overflow

      hdps = ebh.collect(start_time, end_time, data_points)

      _(hdps.size).must_equal(3) # 2 regular + 1 overflow

      overflow_point = hdps.find { |hdp| hdp.attributes == { 'otel.metric.overflow' => true } }
      _(overflow_point).wont_be_nil
      _(overflow_point.count).must_equal(2) # Both overflow measurements merged
      _(overflow_point.sum).must_equal(25) # 10 + 15
    end

    describe 'edge cases' do
      it 'handles cardinality limit 0' do
        # Test cardinality limit of 0 - everything overflows
        cardinality_limit = 0
        ebh.update(5, { 'key' => 'value' }, data_points, cardinality_limit)

        hdps = ebh.collect(start_time, end_time, data_points)

        _(hdps.size).must_equal(1)
        overflow_point = hdps.find { |hdp| hdp.attributes == { 'otel.metric.overflow' => true } }
        _(overflow_point).wont_be_nil
        _(overflow_point.count).must_equal(1)
        _(overflow_point.sum).must_equal(5)
        _(overflow_point.min).must_equal(5)
        _(overflow_point.max).must_equal(5)
      end

      it 'handles cardinality limit 1' do
        # Test cardinality limit of 1 with bucket counts preservation
        cardinality_limit = 1
        ebh.update(1, { 'key' => 'a' }, data_points, cardinality_limit)
        ebh.update(10, { 'key' => 'b' }, data_points, cardinality_limit) # Overflow
        ebh.update(100, { 'key' => 'c' }, data_points, cardinality_limit) # More overflow

        hdps = ebh.collect(start_time, end_time, data_points)
        overflow_point = hdps.find { |hdp| hdp.attributes == { 'otel.metric.overflow' => true } }

        # Check bucket counts are properly merged
        _(overflow_point.bucket_counts).wont_be_nil
        _(overflow_point.bucket_counts.sum).must_equal(overflow_point.count)
        _(overflow_point.min).must_equal(10)
        _(overflow_point.max).must_equal(100)
      end

      it 'handles very large cardinality scenarios' do
        cardinality_limit = 100

        # Add 150 unique attribute sets
        150.times do |i|
          ebh.update(i, { 'unique_key' => "value_#{i}" }, data_points, cardinality_limit)
        end

        hdps = ebh.collect(start_time, end_time, data_points)

        _(hdps.size).must_equal(101) # 100 + 1
        overflow_point = hdps.find { |hdp| hdp.attributes == { 'otel.metric.overflow' => true } }
        _(overflow_point).wont_be_nil
        _(overflow_point.count).must_equal(50) # 150 - 100
      end
    end
  end
end
