# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::LastValue do
  let(:data_points) { {} }
  let(:last_value_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new(aggregation_temporality: aggregation_temporality) }
  let(:aggregation_temporality) { :delta }

  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#initialize' do
    it 'defaults to the delta aggregation temporality' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality delta as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new(aggregation_temporality: :delta)
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality cumulative as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new(aggregation_temporality: :cumulative)
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'invalid aggregation_temporality pickles as symbol from parameters return to defaults delta' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new(aggregation_temporality: :pickles)
      _(exp.aggregation_temporality).must_equal :delta
    end
  end

  it 'sets the timestamps' do
    last_value_aggregation.update(0, {}, data_points)
    ndp = last_value_aggregation.collect(start_time, end_time, data_points)[0]
    _(ndp.start_time_unix_nano).must_equal(start_time)
    _(ndp.time_unix_nano).must_equal(end_time)
  end

  it 'aggregates and collects should collect the last value' do
    last_value_aggregation.update(1, {}, data_points)
    last_value_aggregation.update(2, {}, data_points)

    last_value_aggregation.update(2, { 'foo' => 'bar' }, data_points)
    last_value_aggregation.update(2, { 'foo' => 'bar' }, data_points)

    ndps = last_value_aggregation.collect(start_time, end_time, data_points)
    _(ndps[0].value).must_equal(2)
    _(ndps[0].attributes).must_equal({}, data_points)

    _(ndps[1].value).must_equal(2)
    _(ndps[1].attributes).must_equal('foo' => 'bar')
  end
end
