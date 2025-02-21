# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../test_helper'

describe OpenTelemetry::SDK do
  describe '#metric_reader' do
    export = OpenTelemetry::SDK::Metrics::Export
    let(:exporter) { export::ConsoleMetricPullExporter.new }

    before do
      reset_metrics_sdk
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      @metric_reader = export::MetricReader.new(exporter: exporter)

      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(@metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test_1')
      @counter = meter.create_counter('counter_1', unit: 'smidgen', description: 'a small amount of something')
    end

    after do
      ENV.delete('OTEL_METRICS_EXPORTER')
    end

    it 'initialize metric_reader' do
      metric_reader = export::MetricReader.new(exporter: exporter)
      _(metric_reader.exporters.first.class).must_equal export::ConsoleMetricPullExporter
    end

    it 'register additional metric_exporter' do
      metric_reader = export::MetricReader.new(exporter: exporter)
      in_memory_exporter = export::InMemoryMetricPullExporter.new
      metric_reader.register_exporter(exporter: in_memory_exporter)
      _(metric_reader.exporters[0].class).must_equal export::ConsoleMetricPullExporter
      _(metric_reader.exporters[1].class).must_equal export::InMemoryMetricPullExporter
    end

    it 'change default aggregator' do
      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation

      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Sum
      _(default_aggregation.aggregation_temporality).must_equal :delta

      @metric_reader.aggregator(aggregator: OpenTelemetry::SDK::Metrics::Aggregation::Drop.new)

      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation
      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Drop
    end

    it 'do not change default aggregator if different instrument kind' do
      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation

      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Sum
      _(default_aggregation.aggregation_temporality).must_equal :delta

      @metric_reader.aggregator(aggregator: OpenTelemetry::SDK::Metrics::Aggregation::Drop.new, instrument_kind: :gauge)

      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation
      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Sum
    end

    it 'change default aggregation_temporality' do
      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation

      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Sum
      _(default_aggregation.aggregation_temporality).must_equal :delta

      @metric_reader.temporality(temporality: :cumulative)

      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation
      _(default_aggregation.aggregation_temporality).must_equal :cumulative
    end

    it 'do not change default aggregation_temporality if different instrument kind' do
      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation

      _(default_aggregation.class).must_equal OpenTelemetry::SDK::Metrics::Aggregation::Sum
      _(default_aggregation.aggregation_temporality).must_equal :delta

      @metric_reader.temporality(temporality: :cumulative, instrument_kind: :gauge)

      default_aggregation = @counter.instance_variable_get(:@metric_streams).first.default_aggregation
      _(default_aggregation.aggregation_temporality).must_equal :delta
    end
  end
end
