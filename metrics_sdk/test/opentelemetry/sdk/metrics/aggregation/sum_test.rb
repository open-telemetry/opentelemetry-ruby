# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Sum do
  let(:data_points) { {} }
  let(:sum_aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality:, monotonic:) }
  let(:aggregation_temporality) { :delta }
  let(:monotonic) { false }

  # Time in nano
  let(:start_time) { (Time.now.to_r * 1_000_000_000).to_i }
  let(:end_time) { ((Time.now + 60).to_r * 1_000_000_000).to_i }

  describe '#initialize' do
    it 'defaults to the cumulative aggregation temporality' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'sets parameters from the environment to cumulative' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
        OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'sets parameters from the environment to delta' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'delta') do
        OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      end
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'sets parameters from the environment and converts them to symbols' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'potato') do
        OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'invalid aggregation_temporality from parameters return default to cumulative' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: 'pickles')
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'valid aggregation_temporality delta from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: 'delta')
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality cumulative from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: 'cumulative')
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'valid aggregation_temporality delta as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: :delta)
      _(exp.aggregation_temporality).must_equal :delta
    end

    it 'valid aggregation_temporality cumulative as symbol from parameters' do
      exp = OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: :cumulative)
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'prefers explicit parameters rather than the environment and converts them to symbols' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'potato') do
        OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: 'pickles')
      end
      _(exp.aggregation_temporality).must_equal :cumulative
    end

    it 'function arguments have higher priority than environment' do
      exp = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
        OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(aggregation_temporality: :delta)
      end
      _(exp.aggregation_temporality).must_equal :delta
    end
  end

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

  it 'aggregates and collects negative values' do
    sum_aggregation.update(1, {}, data_points)
    sum_aggregation.update(-2, {}, data_points)

    ndps = sum_aggregation.collect(start_time, end_time, data_points)
    _(ndps[0].value).must_equal(-1)
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

  describe 'when sum type is monotonic' do
    let(:aggregation_temporality) { :not_delta }
    let(:monotonic) { true }

    it 'does not allow negative values to accumulate' do
      sum_aggregation.update(1, {}, data_points)
      sum_aggregation.update(-2, {}, data_points)
      ndps = sum_aggregation.collect(start_time, end_time, data_points)

      _(ndps[0].value).must_equal(1)
    end
  end
end
