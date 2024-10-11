# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#periodic_metric_reader' do
    before { reset_metrics_sdk }

    it 'emits 2 metrics after 10 seconds' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })

      sleep(8)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      _(snapshot.size).must_equal(2)

      first_snapshot = snapshot
      _(first_snapshot[0].name).must_equal('counter')
      _(first_snapshot[0].unit).must_equal('smidgen')
      _(first_snapshot[0].description).must_equal('a small amount of something')

      _(first_snapshot[0].instrumentation_scope.name).must_equal('test')

      _(first_snapshot[0].data_points[0].value).must_equal(1)
      _(first_snapshot[0].data_points[0].attributes).must_equal({})

      _(first_snapshot[0].data_points[1].value).must_equal(4)
      _(first_snapshot[0].data_points[1].attributes).must_equal('a' => 'b')

      _(first_snapshot[0].data_points[2].value).must_equal(3)
      _(first_snapshot[0].data_points[2].attributes).must_equal('b' => 'c')

      _(first_snapshot[0].data_points[3].value).must_equal(4)
      _(first_snapshot[0].data_points[3].attributes).must_equal('d' => 'e')

      _(periodic_metric_reader.instance_variable_get(:@thread).alive?).must_equal false
    end

    it 'emits 1 metric after 1 second when interval is > 1 second' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      periodic_metric_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(export_interval_millis: 5000, export_timeout_millis: 5000, exporter: metric_exporter)

      OpenTelemetry.meter_provider.add_metric_reader(periodic_metric_reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })
      counter.add(4, attributes: { 'd' => 'e' })

      sleep(1)

      periodic_metric_reader.shutdown
      snapshot = metric_exporter.metric_snapshots

      _(snapshot.size).must_equal(1)
      _(periodic_metric_reader.instance_variable_get(:@thread).alive?).must_equal false
    end
  end
end
