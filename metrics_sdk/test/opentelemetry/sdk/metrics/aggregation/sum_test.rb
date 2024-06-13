# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Sum do
  let(:data_points) { {} }
  let(:sum_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: aggregation_temporality) }
  let(:aggregation_temporality) { :delta }

  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  it 'sets the timestamps' do
    sum_aggregation.update(0, {}, data_points)
    ndp = sum_aggregation.collect(start_time, end_time, data_points)[0]
    _(ndp.start_time_unix_nano).must_equal(start_time)
    _(ndp.time_unix_nano).must_equal(end_time)
  end

  it 'aggregates and collects' do
    sum_aggregation.update(1, {}, data_points)
    sum_aggregation.update(2, {}, data_points)

    sum_aggregation.update(2, { 'foo' => 'bar' }, data_points)
    sum_aggregation.update(2, { 'foo' => 'bar' }, data_points)

    ndps = sum_aggregation.collect(start_time, end_time, data_points)
    _(ndps[0].value).must_equal(3)
    _(ndps[0].attributes).must_equal({}, data_points)

    _(ndps[1].value).must_equal(4)
    _(ndps[1].attributes).must_equal('foo' => 'bar')
  end

  it 'does not aggregate between collects' do
    sum_aggregation.update(1, {}, data_points)
    sum_aggregation.update(2, {}, data_points)
    ndps = sum_aggregation.collect(start_time, end_time, data_points)

    sum_aggregation.update(1, {}, data_points)
    # Assert that the recent update does not
    # impact the already collected metrics
    _(ndps[0].value).must_equal(3)

    ndps = sum_aggregation.collect(start_time, end_time, data_points)
    # Assert that we are not accumulating values
    # between calls to collect
    _(ndps[0].value).must_equal(1)
  end

  describe 'when aggregation_temporality is not delta' do
    let(:aggregation_temporality) { :not_delta }

    it 'allows metrics to accumulate' do
      sum_aggregation.update(1, {}, data_points)
      sum_aggregation.update(2, {}, data_points)
      ndps = sum_aggregation.collect(start_time, end_time, data_points)

      sum_aggregation.update(1, {}, data_points)
      # Assert that the recent update does not
      # impact the already collected metrics
      _(ndps[0].value).must_equal(3)

      ndps = sum_aggregation.collect(start_time, end_time, data_points)
      # Assert that we are accumulating values
      # and not just capturing the delta since
      # the previous collect call
      _(ndps[0].value).must_equal(4)
    end
  end
end
