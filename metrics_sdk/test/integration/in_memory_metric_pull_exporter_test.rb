# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    before { reset_metrics_sdk }

    it 'emits metrics' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('counter')
      _(last_snapshot[0].unit).must_equal('smidgen')
      _(last_snapshot[0].description).must_equal('a small amount of something')

      _(last_snapshot[0].instrumentation_scope.name).must_equal('test')

      _(last_snapshot[0].data_points[0].value).must_equal(1)
      _(last_snapshot[0].data_points[0].attributes).must_equal({})

      _(last_snapshot[0].data_points[1].value).must_equal(4)
      _(last_snapshot[0].data_points[1].attributes).must_equal('a' => 'b')

      _(last_snapshot[0].data_points[2].value).must_equal(3)
      _(last_snapshot[0].data_points[2].attributes).must_equal('b' => 'c')

      _(last_snapshot[0].data_points[3].value).must_equal(4)
      _(last_snapshot[0].data_points[3].attributes).must_equal('d' => 'e')

      _(last_snapshot[0].aggregation_temporality).must_equal(:cumulative)
    end

    describe 'cardinality limit' do
      before do
        OpenTelemetry::SDK.configure
      end
      it 'accepts cardinality_limit parameter on initialization' do
        metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(aggregation_cardinality_limit: 100)
        OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

        meter = OpenTelemetry.meter_provider.meter('test')
        counter = meter.create_counter('test_counter')
        counter.add(1)

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot).wont_be_empty
      end

      it 'enforces cardinality limit when collecting metrics' do
        metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(aggregation_cardinality_limit: 2)
        OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

        meter = OpenTelemetry.meter_provider.meter('test')
        counter = meter.create_counter('test_counter')

        # Add more data points than the cardinality limit
        counter.add(1, attributes: { 'key' => 'a' })
        counter.add(2, attributes: { 'key' => 'b' })
        counter.add(3, attributes: { 'key' => 'c' }) # Should trigger overflow

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot[0].data_points.size).must_equal(3)

        # Find overflow data point
        overflow_point = last_snapshot[0].data_points.find do |dp|
          dp.attributes == { 'otel.metric.overflow' => true }
        end
        _(overflow_point).wont_be_nil
        _(overflow_point.value).must_equal(3)
      end

      it 'handles zero cardinality limit' do
        metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(aggregation_cardinality_limit: 0)
        OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

        meter = OpenTelemetry.meter_provider.meter('test')
        counter = meter.create_counter('test_counter')

        counter.add(42, attributes: { 'key' => 'value' })

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots

        _(last_snapshot[0].data_points.size).must_equal(1)

        # All should go to overflow
        overflow_point = last_snapshot[0].data_points.find do |dp|
          dp.attributes == { 'otel.metric.overflow' => true }
        end
        _(overflow_point).wont_be_nil
        _(overflow_point.value).must_equal(42)
      end
    end
  end
end
