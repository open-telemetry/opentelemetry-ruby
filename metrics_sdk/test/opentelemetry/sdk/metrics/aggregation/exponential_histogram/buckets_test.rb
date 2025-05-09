# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::Buckets do
  let(:buckets) { OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::Buckets.new }

  it 'buckets initialization' do
    _(buckets.index_start).must_equal(0)
    _(buckets.index_end).must_equal(0)
    _(buckets.index_base).must_equal(0)
    _(buckets.offset).must_equal(0)
    _(buckets.offset_counts).must_equal([0])
    _(buckets.instance_variable_get(:@counts)).must_equal([0])
    _(buckets.get_bucket(0)).must_equal(0)
    _(buckets.length).must_equal(0)
    assert_nil(buckets.get_bucket(1))
  end

  it 'buckets grow' do
    buckets.grow(5, 15)
    _(buckets.instance_variable_get(:@counts).count).must_equal(8)
    _(buckets.length).must_equal(0)

    buckets.grow(10, 15)
    _(buckets.instance_variable_get(:@counts).count).must_equal(15)
    _(buckets.length).must_equal(0)
  end

  it 'buckets increment value in bucket' do
    buckets.grow(5, 15)

    buckets.increment_bucket(3)
    _(buckets.get_bucket(3)).must_equal(1)

    buckets.increment_bucket(3, 4)
    _(buckets.get_bucket(3)).must_equal(5)
  end

  describe 'buckets downscale' do
    it 'test basic downscale' do
      buckets.index_start = 0
      buckets.index_end = 7
      buckets.index_base = 0
      buckets.instance_variable_set(:@counts, [1, 2, 3, 4, 5, 6, 7, 8])

      buckets.downscale(1)

      assert_equal [3, 7, 11, 15, 0, 0, 0, 0], buckets.counts
      assert_equal 0, buckets.index_start
      assert_equal 3, buckets.index_end
    end

    it 'test basic downscale with base' do
      buckets.index_start = 2
      buckets.index_end = 9
      buckets.index_base = 4
      buckets.instance_variable_set(:@counts, [0, 0, 1, 2, 3, 4, 5, 6, 7, 8])

      buckets.downscale(1)

      assert_equal [15, 0, 3, 7, 0, 0, 0, 0, 5, 6], buckets.counts
      assert_equal 1, buckets.index_start
      assert_equal 4, buckets.index_end
    end

    it 'test downscale with larger factor' do
      buckets.index_start = 0
      buckets.index_end = 15
      buckets.index_base = 0
      buckets.instance_variable_set(:@counts, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])

      buckets.downscale(2)

      assert_equal [4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], buckets.counts
      assert_equal 0, buckets.index_start
      assert_equal 3, buckets.index_end
    end

    it 'test downscale with negative index' do
      buckets.index_start = -4
      buckets.index_end = 3
      buckets.index_base = -4
      buckets.instance_variable_set(:@counts, [1, 2, 3, 4, 5, 6, 7, 8])

      buckets.downscale(2)

      assert_equal [10, 26, 0, 0, 0, 0, 0, 0], buckets.counts
      assert_equal(-1, buckets.index_start)
      assert_equal 0, buckets.index_end
    end

    it 'test downscale with 0 buckets' do
      buckets.index_start = 0
      buckets.index_end = 0
      buckets.index_base = 0
      buckets.instance_variable_set(:@counts, [])

      buckets.downscale(2)

      assert_empty buckets.counts
      assert_equal 0, buckets.index_start
      assert_equal 0, buckets.index_end
    end

    it 'test downscale with single buckets' do
      buckets.index_start = 0
      buckets.index_end = 0
      buckets.index_base = 0
      buckets.instance_variable_set(:@counts, [42])

      buckets.downscale(2)

      assert_equal [42], buckets.counts
      assert_equal 0, buckets.index_start
      assert_equal 0, buckets.index_end
    end
  end
end
