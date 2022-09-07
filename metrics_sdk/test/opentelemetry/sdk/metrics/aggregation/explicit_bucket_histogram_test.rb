# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram do
  let(:ebh) do
    OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(
      aggregation_temporality: aggregation_temporality,
      boundaries: boundaries,
      record_min_max: record_min_max
    )
  end
  let(:boundaries) { [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000] }
  let(:record_min_max) { true }
  let(:aggregation_temporality) { :delta }
  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#collect' do
    it 'returns all the data points' do
      ebh.update(0, {})
      ebh.update(1, {})
      ebh.update(5, {})
      ebh.update(6, {})
      ebh.update(10, {})

      ebh.update(-10, 'foo' => 'bar')
      ebh.update(1, 'foo' => 'bar')
      ebh.update(22, 'foo' => 'bar')
      ebh.update(55, 'foo' => 'bar')
      ebh.update(80, 'foo' => 'bar')

      hdps = ebh.collect(start_time, end_time)
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
      ebh.update(0, {})
      hdp = ebh.collect(start_time, end_time)[0]
      _(hdp.start_time_unix_nano).must_equal(start_time)
      _(hdp.time_unix_nano).must_equal(end_time)
    end

    it 'calculates the count' do
      ebh.update(0, {})
      ebh.update(0, {})
      ebh.update(0, {})
      ebh.update(0, {})
      hdp = ebh.collect(start_time, end_time)[0]
      _(hdp.count).must_equal(4)
    end

    it 'does not aggregate between collects with default delta aggregation' do
      ebh.update(0, {})
      ebh.update(1, {})
      ebh.update(5, {})
      ebh.update(6, {})
      ebh.update(10, {})
      hdps = ebh.collect(start_time, end_time)

      ebh.update(0, {})
      ebh.update(1, {})
      ebh.update(5, {})
      ebh.update(6, {})
      ebh.update(10, {})
      # Assert that the recent update does not
      # impact the already collected metrics
      _(hdps[0].count).must_equal(5)
      _(hdps[0].sum).must_equal(22)
      _(hdps[0].min).must_equal(0)
      _(hdps[0].max).must_equal(10)
      _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])

      hdps = ebh.collect(start_time, end_time)
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
        ebh.update(0, {})
        ebh.update(1, {})
        ebh.update(5, {})
        ebh.update(6, {})
        ebh.update(10, {})
        hdps = ebh.collect(start_time, end_time)

        ebh.update(0, {})
        ebh.update(1, {})
        ebh.update(5, {})
        ebh.update(6, {})
        ebh.update(10, {})
        # Assert that the recent update does not
        # impact the already collected metrics
        _(hdps[0].count).must_equal(5)
        _(hdps[0].sum).must_equal(22)
        _(hdps[0].min).must_equal(0)
        _(hdps[0].max).must_equal(10)
        _(hdps[0].bucket_counts).must_equal([1, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0])

        hdps1 = ebh.collect(start_time, end_time)
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
      ebh.update(0, {})

      ebh.update(1, {})
      ebh.update(5, {})

      ebh.update(6, {})
      ebh.update(10, {})

      ebh.update(11, {})
      ebh.update(25, {})

      ebh.update(26, {})
      ebh.update(50, {})

      ebh.update(51, {})
      ebh.update(75, {})

      ebh.update(76, {})
      ebh.update(100, {})

      ebh.update(101, {})
      ebh.update(250, {})

      ebh.update(251, {})
      ebh.update(500, {})

      ebh.update(501, {})
      ebh.update(1000, {})

      ebh.update(1001, {})

      hdp = ebh.collect(start_time, end_time)[0]
      _(hdp.bucket_counts).must_equal([1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1])
      _(hdp.sum).must_equal(4040)
      _(hdp.min).must_equal(0)
      _(hdp.max).must_equal(1001)
    end

    describe 'with an unsorted boundary set' do
      let(:boundaries) { [4, 2, 1] }

      it 'sorts it' do
        ebh.update(0, {})
        _(ebh.collect(start_time, end_time)[0].explicit_bounds).must_equal([1, 2, 4])
      end
    end

    describe 'with recording min max disabled' do
      let(:record_min_max) { false }

      it 'does not record min max values' do
        ebh.update(-1, {})
        hdp = ebh.collect(start_time, end_time)[0]
        _(hdp.min).must_be_nil
        _(hdp.min).must_be_nil
      end
    end

    describe 'with custom boundaries' do
      let(:boundaries) { [0, 2, 4] }

      it 'aggregates' do
        ebh.update(-1, {})
        ebh.update(0, {})
        ebh.update(1, {})
        ebh.update(2, {})
        ebh.update(3, {})
        ebh.update(4, {})
        ebh.update(5, {})
        hdp = ebh.collect(start_time, end_time)[0]

        _(hdp.bucket_counts).must_equal([2, 2, 2, 1])
      end
    end

    describe 'with a single boundary value' do
      let(:boundaries) { [0] }

      it 'aggregates' do
        ebh.update(-1, {})
        ebh.update(1, {})
        hdp = ebh.collect(start_time, end_time)[0]

        _(hdp.bucket_counts).must_equal([1, 1])
      end
    end

    describe 'with an empty boundary value' do
      let(:boundaries) { [] }

      it 'aggregates but does not record bucket counts' do
        ebh.update(-1, {})
        ebh.update(3, {})
        hdp = ebh.collect(start_time, end_time)[0]

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
        ebh.update(-1, {})
        ebh.update(3, {})
        hdp = ebh.collect(start_time, end_time)[0]

        _(hdp.bucket_counts).must_be_nil
        _(hdp.explicit_bounds).must_be_nil
        _(hdp.sum).must_equal(2)
        _(hdp.count).must_equal(2)
        _(hdp.min).must_equal(-1)
        _(hdp.max).must_equal(3)
      end
    end
  end
end
