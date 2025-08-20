# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Drop do
  let(:drop_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Drop.new }
  let(:aggregation_temporality) { :delta }

  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#initialize' do
    # drop aggregation doesn't care about aggregation_temporality since all data will be dropped
  end

  it 'sets the timestamps' do
    drop_aggregation.update(0, {})
    ndp = drop_aggregation.collect(start_time, end_time)[0]
    _(ndp.start_time_unix_nano).must_equal(0)
    _(ndp.time_unix_nano).must_equal(0)
  end

  it 'aggregates and collects should collect no value for all collection' do
    drop_aggregation.update(1, {})
    drop_aggregation.update(2, {})

    drop_aggregation.update(2, { 'foo' => 'bar' })
    drop_aggregation.update(2, { 'foo' => 'bar' })

    ndps = drop_aggregation.collect(start_time, end_time)

    _(ndps.size).must_equal(2)
    _(ndps[0].value).must_equal(0)
    _(ndps[0].attributes).must_equal({})

    _(ndps[1].value).must_equal(0)
    _(ndps[1].attributes).must_equal({})
  end
end
