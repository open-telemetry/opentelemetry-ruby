# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Drop do
  let(:data_points) { {} }
  let(:drop_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Drop.new }
  let(:aggregation_temporality) { :delta }
  let(:cardinality_limit) { 2000 }
  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#initialize' do
    # drop aggregation doesn't care about aggregation_temporality since all data will be dropped
  end

  it 'sets the timestamps' do
    drop_aggregation.update(0, {}, data_points, cardinality_limit)
    ndp = drop_aggregation.collect(start_time, end_time, data_points, cardinality_limit)[0]
    _(ndp.start_time_unix_nano).must_equal(0)
    _(ndp.time_unix_nano).must_equal(0)
  end

  it 'aggregates and collects should collect no value for all collection' do
    drop_aggregation.update(1, {}, data_points, cardinality_limit)
    drop_aggregation.update(2, {}, data_points, cardinality_limit)

    drop_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)
    drop_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)

    ndps = drop_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

    _(ndps.size).must_equal(2)
    _(ndps[0].value).must_equal(0)
    _(ndps[0].attributes).must_equal({})

    _(ndps[1].value).must_equal(0)
    _(ndps[1].attributes).must_equal({})
  end

  describe 'cardinality limit' do
    let(:cardinality_limit) { 2 }

    it 'respects cardinality limit but still drops all values' do
      drop_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
      drop_aggregation.update(20, { 'key' => 'b' }, data_points, cardinality_limit)
      drop_aggregation.update(30, { 'key' => 'c' }, data_points, cardinality_limit) # Should be limited
      drop_aggregation.update(40, { 'key' => 'd' }, data_points, cardinality_limit) # Should be limited

      ndps = drop_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

      # All values should be 0 regardless of cardinality limit
      ndps.each do |ndp|
        _(ndp.value).must_equal(0)
      end
    end

    describe 'edge cases' do
      it 'handles cardinality limit of 0 gracefully' do
        cardinality_limit = 0
        drop_aggregation.update(100, { 'key' => 'value' }, data_points, cardinality_limit)

        ndps = drop_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

        # Drop aggregation should still produce data points even with 0 limit
        _(ndps).wont_be_empty
        ndps.each { |ndp| _(ndp.value).must_equal(0) }
      end

      it 'maintains drop behavior with very high cardinality' do
        cardinality_limit = 1000

        100.times do |i|
          drop_aggregation.update(i * 10, { 'key' => "value_#{i}" }, data_points, cardinality_limit)
        end

        ndps = drop_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

        # All values should still be 0
        ndps.each { |ndp| _(ndp.value).must_equal(0) }
        _(ndps.size).must_equal(100) # All data points should be present
      end
    end
  end
end
