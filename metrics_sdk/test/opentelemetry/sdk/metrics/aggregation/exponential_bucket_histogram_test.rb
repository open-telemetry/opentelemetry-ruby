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
  let(:record_min_max) { true }
  let(:max_size) { 20 }
  let(:max_scale) { 5 }
  let(:aggregation_temporality) { :delta }
  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#collect' do
    it 'returns all the data points' do
      expbh.update(1.03, {})
      expbh.update(1.23, {})
      expbh.update(0, {})

      expbh.update(1.45, {'foo' => 'bar'})
      expbh.update(1.67, {'foo' => 'bar'})

      exphdps = expbh.collect(start_time, end_time)

      _(exphdps.size).must_equal(2)
      _(exphdps[0].attributes).must_equal({})
      _(exphdps[0].count).must_equal(3)
      _(exphdps[0].sum).must_equal(2.26)
      _(exphdps[0].min).must_equal(0)
      _(exphdps[0].max).must_equal(1.23)
      _(exphdps[0].scale).must_equal(5)
      _(exphdps[0].zero_count).must_equal(1)
      _(exphdps[0].positive.counts).must_equal([0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0])
      _(exphdps[0].negative.counts).must_equal([0])
      _(exphdps[0].zero_threshold).must_equal(0)

      _(exphdps[1].attributes).must_equal('foo' => 'bar')
      _(exphdps[1].count).must_equal(2)
      _(exphdps[1].sum).must_equal(3.12)
      _(exphdps[1].min).must_equal(1.45)
      _(exphdps[1].max).must_equal(1.67)
      _(exphdps[1].scale).must_equal(4)
      _(exphdps[1].zero_count).must_equal(0)
      _(exphdps[1].positive.counts).must_equal([0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0])
      _(exphdps[1].negative.counts).must_equal([0])
      _(exphdps[1].zero_threshold).must_equal(0)
    end

    it 'rescale_with_alternating_growth_0' do
      # Tests insertion of [2, 4, 1]. The index of 2 (i.e., 0) becomes
      # `indexBase`, the 4 goes to its right and the 1 goes in the last
      # position of the backing array. With 3 binary orders of magnitude
      # and MaxSize=4, this must finish with scale=0; with minimum value 1
      # this must finish with offset=-1 (all scales).

      # The corresponding Go test is TestAlternatingGrowth1 where:
      # agg := NewFloat64(NewConfig(WithMaxSize(4)))
      # agg is an instance of github.com/lightstep/otel-launcher-go/lightstep/sdk/metric/aggregator/histogram/structure.Histogram[float64]
      expbh = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(
        aggregation_temporality: aggregation_temporality,
        record_min_max: record_min_max,
        max_size: 4,
        max_scale: 20, # use default value of max scale; should downscale to 0
        zero_threshold: 0
      )

      expbh.update(2, {})
      expbh.update(4, {})
      expbh.update(1, {})

      exphdps = expbh.collect(start_time, end_time)

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

      expbh.update(2, {})
      expbh.update(2, {})
      expbh.update(2, {})
      expbh.update(1, {})
      expbh.update(8, {})
      expbh.update(0.5, {})

      exphdps = expbh.collect(start_time, end_time)

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

    it 'test_merge' do
      # TODO
    end
  end
end
