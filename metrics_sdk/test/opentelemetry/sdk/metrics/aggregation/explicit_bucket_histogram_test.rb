# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram do
  let(:ebh) { OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.new(boundaries: boundaries, record_min_max: record_min_max) }
  let(:boundaries) { [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000] }
  let(:record_min_max) { true }
  let(:now_in_nano) { (Time.now.to_r * 1_000_000_000).to_i }

  describe '#collect' do
    it 'returns all the data points' do
      ebh.update(0, {})
      ebh.update(1, {})
      ebh.update(5, {})
      ebh.update(6, {})
      ebh.update(10, {})

      ebh.update(0, { 'foo' => 'bar' })
      ebh.update(1, { 'foo' => 'bar' })
      ebh.update(5, { 'foo' => 'bar' })
      ebh.update(6, { 'foo' => 'bar' })
      ebh.update(10, { 'foo' => 'bar' })

      hdps = ebh.collect(now_in_nano, now_in_nano)
      _(hdps.size).must_equal(2)
    end

    it 'sets the timestamps' do
      ebh.update(0, {})
      hdp = ebh.collect(now_in_nano, now_in_nano)[0]
      _(hdp.start_time_unix_nano).must_equal(now_in_nano)
      _(hdp.time_unix_nano).must_equal(now_in_nano)
    end

    it 'calculates the bucket count' do
      ebh.update(0, {})
      ebh.update(0, {})
      ebh.update(0, {})
      ebh.update(0, {})
      hdp = ebh.collect(now_in_nano, now_in_nano)[0]
      _(hdp.count).must_equal(4)
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

      hdp = ebh.collect(now_in_nano, now_in_nano)[0]
      _(hdp.bucket_counts).must_equal([1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1])
      _(hdp.sum).must_equal(4040)
      _(hdp.min).must_equal(0)
      _(hdp.max).must_equal(1001)
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
      end
    end

    describe 'with a single boundary value' do
      let(:boundaries) { [0] }

      it 'aggregates' do
        ebh.update(-1, {})
        ebh.update(1, {})
        hdp = ebh.collect(now_in_nano, now_in_nano)[0]

        _(hdp.bucket_counts).must_equal([1, 1])
      end
    end

    describe 'with an empty boundary value' do
      let(:boundaries) { [] }

      it 'aggregates' do
        ebh.update(-1, {})
        ebh.update(1, {})
        hdp = ebh.collect(now_in_nano, now_in_nano)[0]

        _(hdp.bucket_counts).must_equal([2])
      end
    end
  end
end
