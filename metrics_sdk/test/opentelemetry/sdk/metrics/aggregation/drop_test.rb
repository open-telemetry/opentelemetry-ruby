# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::LastValue do
  let(:data_points) { {} }
  let(:drop_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Drop.new(aggregation_temporality: aggregation_temporality) }
  let(:aggregation_temporality) { :delta }

  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  it 'sets the timestamps' do
    drop_aggregation.update(0, {}, data_points)
    ndp = drop_aggregation.collect(start_time, end_time, data_points)[0]
    _(ndp.start_time_unix_nano).must_equal(0)
    _(ndp.time_unix_nano).must_equal(0)
  end

  it 'aggregates and collects should collect no value for all collection' do
    drop_aggregation.update(1, {}, data_points)
    drop_aggregation.update(2, {}, data_points)

    drop_aggregation.update(2, { 'foo' => 'bar' }, data_points)
    drop_aggregation.update(2, { 'foo' => 'bar' }, data_points)

    ndps = drop_aggregation.collect(start_time, end_time, data_points)

    _(ndps.size).must_equal(2)
    _(ndps[0].value).must_equal(0)
    _(ndps[0].attributes).must_equal({})

    _(ndps[1].value).must_equal(0)
    _(ndps[1].attributes).must_equal({})
  end
end
