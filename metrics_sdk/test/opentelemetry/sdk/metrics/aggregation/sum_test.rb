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
  let(:cardinality_limit) { 2000 }

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
    sum_aggregation.update(0, {}, data_points, cardinality_limit)
    ndp = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)[0]
    _(ndp.start_time_unix_nano).must_equal(start_time)
    _(ndp.time_unix_nano).must_equal(end_time)
  end

  it 'aggregates and collects' do
    sum_aggregation.update(1, {}, data_points, cardinality_limit)
    sum_aggregation.update(2, {}, data_points, cardinality_limit)

    sum_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)
    sum_aggregation.update(2, { 'foo' => 'bar' }, data_points, cardinality_limit)

    ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)
    _(ndps[0].value).must_equal(3)
    _(ndps[0].attributes).must_equal({}, data_points)

    _(ndps[1].value).must_equal(4)
    _(ndps[1].attributes).must_equal('foo' => 'bar')
  end

  it 'aggregates and collects negative values' do
    sum_aggregation.update(1, {}, data_points, cardinality_limit)
    sum_aggregation.update(-2, {}, data_points, cardinality_limit)

    ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)
    _(ndps[0].value).must_equal(-1)
  end

  it 'does not aggregate between collects' do
    sum_aggregation.update(1, {}, data_points, cardinality_limit)
    sum_aggregation.update(2, {}, data_points, cardinality_limit)
    ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

    sum_aggregation.update(1, {}, data_points, cardinality_limit)
    # Assert that the recent update does not
    # impact the already collected metrics
    _(ndps[0].value).must_equal(3)

    ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)
    # Assert that we are not accumulating values
    # between calls to collect
    _(ndps[0].value).must_equal(1)
  end

  describe 'when aggregation_temporality is not delta' do
    let(:aggregation_temporality) { :not_delta }

    it 'allows metrics to accumulate' do
      sum_aggregation.update(1, {}, data_points, cardinality_limit)
      sum_aggregation.update(2, {}, data_points, cardinality_limit)
      ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

      sum_aggregation.update(1, {}, data_points, cardinality_limit)
      # Assert that the recent update does not
      # impact the already collected metrics
      _(ndps[0].value).must_equal(3)

      ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)
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
      sum_aggregation.update(1, {}, data_points, cardinality_limit)
      sum_aggregation.update(-2, {}, data_points, cardinality_limit)
      ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

      _(ndps[0].value).must_equal(1)
    end
  end

  describe 'cardinality limit' do
    let(:cardinality_limit) { 3 }

    it 'creates overflow data point when cardinality limit is exceeded' do
      sum_aggregation.update(1, { 'key' => 'a' }, data_points, cardinality_limit)
      sum_aggregation.update(2, { 'key' => 'b' }, data_points, cardinality_limit)
      sum_aggregation.update(3, { 'key' => 'c' }, data_points, cardinality_limit)
      sum_aggregation.update(4, { 'key' => 'd' }, data_points, cardinality_limit) # This should overflow

      ndps = sum_aggregation.collect(start_time, end_time, data_points, cardinality_limit)

      _(ndps.size).must_equal(4)

      overflow_point = ndps.find { |ndp| ndp.attributes == { 'otel.metric.overflow' => true } }
      _(overflow_point).wont_be_nil
      _(overflow_point.value).must_equal(4)
    end

    describe 'with cumulative aggregation' do
      it 'preserves pre-overflow attributes after overflow starts' do
        sum_aggregation.update(1, { 'key' => 'a' }, data_points, cardinality_limit)
        sum_aggregation.update(2, { 'key' => 'b' }, data_points, cardinality_limit)
        sum_aggregation.update(3, { 'key' => 'c' }, data_points, cardinality_limit)
        sum_aggregation.update(4, { 'key' => 'd' }, data_points, cardinality_limit) # This should overflow

        # Add more to a pre-overflow attribute
        sum_aggregation.update(5, { 'key' => 'a' }, data_points, cardinality_limit)

        _(data_points.size).must_equal(4) # 3 original + 1 overflow
        _(data_points[{ 'key' => 'a' }].value).must_equal(6) # 1 + 5
      end
    end

    describe 'edge cases' do
      it 'handles cardinality limit of 1' do
        cardinality_limit = 1
        sum_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)
        sum_aggregation.update(20, { 'key' => 'b' }, data_points, cardinality_limit) # Should overflow immediately

        _(data_points.size).must_equal(2)
        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point).wont_be_nil
        _(overflow_point.value).must_equal(20)
      end

      it 'handles cardinality limit of 0' do
        cardinality_limit = 0
        sum_aggregation.update(10, { 'key' => 'a' }, data_points, cardinality_limit)

        _(data_points.size).must_equal(1)
        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point).wont_be_nil
        _(overflow_point.value).must_equal(10)
      end

      it 'accumulates multiple overflow values correctly' do
        cardinality_limit = 2
        sum_aggregation.update(1, { 'key' => 'a' }, data_points, cardinality_limit)
        sum_aggregation.update(2, { 'key' => 'b' }, data_points, cardinality_limit)
        sum_aggregation.update(3, { 'key' => 'c' }, data_points, cardinality_limit) # Overflow
        sum_aggregation.update(4, { 'key' => 'd' }, data_points, cardinality_limit) # More overflow
        sum_aggregation.update(5, { 'key' => 'e' }, data_points, cardinality_limit) # Even more overflow

        _(data_points.size).must_equal(3) # 2 regular + 1 overflow
        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point.value).must_equal(12) # 3 + 4 + 5
      end

      it 'handles empty attributes correctly with cardinality limit' do
        cardinality_limit = 1
        sum_aggregation.update(10, {}, data_points, cardinality_limit)
        sum_aggregation.update(20, { 'key' => 'value' }, data_points, cardinality_limit) # Should overflow

        _(data_points.size).must_equal(2)
        overflow_point = data_points[{ 'otel.metric.overflow' => true }]
        _(overflow_point).wont_be_nil
        _(overflow_point.value).must_equal(20)
      end

      it 'handles identical attribute sets correctly' do
        cardinality_limit = 2
        attrs = { 'service' => 'test', 'endpoint' => '/api' }
        sum_aggregation.update(1, attrs, data_points, cardinality_limit)
        sum_aggregation.update(2, attrs, data_points, cardinality_limit) # Same attributes, should accumulate
        sum_aggregation.update(3, { 'different' => 'attrs' }, data_points, cardinality_limit)
        sum_aggregation.update(4, { 'another' => 'set' }, data_points, cardinality_limit) # Should overflow

        _(data_points.size).must_equal(3) # 2 unique + 1 overflow
        _(data_points[attrs].value).must_equal(3) # 1 + 2
      end
    end
  end
end
