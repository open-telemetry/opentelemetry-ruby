# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality do
  describe '.determine_temporality' do
    describe 'with CUMULATIVE preference' do
      it 'returns cumulative for counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
        _(result.delta?).must_equal false
      end

      it 'returns cumulative for observable_counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :observable_counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end

      it 'returns cumulative for histogram instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :histogram,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end

      it 'returns cumulative for up_down_counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :up_down_counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end

      it 'returns cumulative for observable_up_down_counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'CUMULATIVE') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :observable_up_down_counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end
    end

    describe 'with DELTA preference' do
      it 'returns delta for counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'delta') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
        _(result.cumulative?).must_equal false
      end

      it 'returns delta for observable_counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'delta') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :observable_counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
      end

      it 'returns delta for histogram instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'DELTA') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :histogram,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
      end
    end

    describe 'with LOWMEMORY preference' do
      it 'returns delta for counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'lowmemory') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
      end

      it 'returns cumulative for observable_counter instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'lowmemory') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :observable_counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end

      it 'returns delta for histogram instrument' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'LOWMEMORY') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :histogram,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
      end
    end

    describe 'with symbol parameters' do
      it 'returns delta when aggregation_temporality is :delta' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: :delta,
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :delta
        _(result.delta?).must_equal true
      end

      it 'returns cumulative when aggregation_temporality is :cumulative' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: :cumulative,
          instrument_kind: :counter,
          default: :delta
        )
        _(result.temporality).must_equal :cumulative
        _(result.cumulative?).must_equal true
      end
    end

    describe 'with case variations' do
      it 'handles uppercase DELTA' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'DELTA',
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :delta
      end

      it 'handles uppercase CUMULATIVE' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'CUMULATIVE',
          instrument_kind: :counter,
          default: :delta
        )
        _(result.temporality).must_equal :cumulative
      end

      it 'handles uppercase LOWMEMORY' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'LOWMEMORY',
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :delta
      end

      it 'handles lowercase delta' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'delta',
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :delta
      end

      it 'handles lowercase cumulative' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'cumulative',
          instrument_kind: :counter,
          default: :delta
        )
        _(result.temporality).must_equal :cumulative
      end

      it 'handles lowercase lowmemory' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'lowmemory',
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :delta
      end
    end

    describe 'with unknown string values' do
      it 'falls back to default when default is :delta' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'unknown',
          instrument_kind: :counter,
          default: :delta
        )
        _(result.temporality).must_equal :delta
      end

      it 'falls back to cumulative when default is :cumulative' do
        result = OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
          aggregation_temporality: 'unknown',
          instrument_kind: :counter,
          default: :cumulative
        )
        _(result.temporality).must_equal :cumulative
      end
    end

    describe 'with environment variable integration' do
      it 'respects OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE set to cumulative' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'cumulative') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :counter,
            default: :delta
          )
        end
        _(result.temporality).must_equal :cumulative
      end

      it 'respects OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE set to delta' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'delta') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :histogram,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
      end

      it 'respects OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE set to lowmemory for non-observable counter' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'lowmemory') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :counter,
            default: :cumulative
          )
        end
        _(result.temporality).must_equal :delta
      end

      it 'respects OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE set to lowmemory for observable counter' do
        result = OpenTelemetry::TestHelpers.with_env('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' => 'lowmemory') do
          OpenTelemetry::SDK::Metrics::Aggregation::AggregationTemporality.determine_temporality(
            aggregation_temporality: ENV['OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'],
            instrument_kind: :observable_counter,
            default: :delta
          )
        end
        _(result.temporality).must_equal :cumulative
      end
    end
  end
end
