# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::LastValue do
  let(:data_points) { {} }
  let(:last_value_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new }
  let(:cardinality_limit) { 2000 }
  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  it 'sets the timestamps' do
    last_value_aggregation.update(0, {}, data_points, cardinality_limit)
    ndp = last_value_aggregation.collect(start_time, end_time, data_points, cardinality_limit)[0]
    _(ndp.start_time_unix_nano).must_equal(start_time)
    _(ndp.time_unix_nano).must_equal(end_time)
  end

  it 'aggregates and collects should collect the last value' do
    last_value_aggregation.update(1, {}, data_points, cardinality_limit)
    last_value_aggregation.update(2, {}, data_points, cardinality_limit)

    last_value_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)
    last_value_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)

    ndps = last_value_aggregation.collect(start_time, end_time, data_points, cardinality_limit)
    _(ndps[0].value).must_equal(2)
    _(ndps[0].attributes).must_equal({}, data_points)

    _(ndps[1].value).must_equal(2)
    _(ndps[1].attributes).must_equal('foo' => 'bar')
  end

  describe 'cardinality limit' do
    let(:cardinality_limit) { 2 }

    it 'creates overflow data point when cardinality limit is exceeded' do
      last_value_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
      last_value_aggregation.update(20, { 'key' => 'b' }, data_points, cardinality_limit)
      last_value_aggregation.update(30, { 'key' => 'c' }, data_points, cardinality_limit) # This should overflow

      ndps = last_value_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

      _(ndps.size).must_equal(2)

      overflow_point = ndps.find { |ndp| ndp.attributes == { 'otel.metric.overflow' => true } }
      _(overflow_point).wont_be_nil
      _(overflow_point.value).must_equal(30)
    end

    it 'updates existing attribute sets without triggering overflow' do
      last_value_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
      last_value_aggregation.update(20, { 'key' => 'b' }, data_points, cardinality_limit)
      last_value_aggregation.update(15, { 'key' => 'a' }, data_points, cardinality_limit) # Update existing

      _(data_points.size).must_equal(2)
      _(data_points[{ 'key' => 'a' }].value).must_equal(15)
      _(data_points[{ 'key' => 'b' }].value).must_equal(20)
    end

    describe 'edge cases' do
      it 'handles cardinality limit of 0' do
        cardinality_limit = 0
        last_value_aggregation.update(42, { 'key' => 'value' }, data_points, cardinality_limit)

        _(data_points.size).must_equal(1)
        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point.value).must_equal(42)
      end

      it 'replaces overflow value with latest when multiple overflow updates' do
        cardinality_limit = 1
        last_value_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
        last_value_aggregation.update(20, { 'key' => 'b' }, data_points, cardinality_limit) # Overflow
        last_value_aggregation.update(30, { 'key' => 'c' }, data_points, cardinality_limit) # Replace overflow

        _(data_points.size).must_equal(2)
        assert_equal(data_points.keys[0], { 'key' => 'a' })
        _(data_points.values[0].value).must_equal 10

        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point.value).must_equal(30) # LastValue behavior - only keep latest
      end

      it 'handles negative values in overflow' do
        cardinality_limit = 1
        last_value_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
        last_value_aggregation.update(-5, { 'key' => 'b' }, data_points, cardinality_limit) # Negative overflow

        assert_equal(data_points.keys[0], { 'key' => 'a' })
        _(data_points.values[0].value).must_equal 10

        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point.value).must_equal(-5)
      end
    end
  end
end
