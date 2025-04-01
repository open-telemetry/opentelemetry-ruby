# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Instrument::Gauge do
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:metric_reader) { OpenTelemetry::SDK::Metrics::Export::MetricReader.new(exporter: metric_exporter) }
  let(:meter) { OpenTelemetry.meter_provider.meter('test') }
  let(:gauge) { meter.create_gauge('gauge', unit: 'smidgen', description: 'a small amount of something') }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(metric_reader)
  end

  it 'gauge should count -2' do
    gauge.record(-2, attributes: { 'foo' => 'bar' })
    metric_reader.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot[0].name).must_equal('gauge')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].attributes).must_equal('foo' => 'bar')
    _(last_snapshot[0].data_points[0].value).must_equal(-2)
    _(last_snapshot[0].aggregation_temporality).must_equal(:delta)
  end

  it 'gauge should count 1 for last recording' do
    gauge.record(-2, attributes: { 'foo' => 'bar' })
    gauge.record(1, attributes: { 'foo' => 'bar' })
    metric_reader.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot.size).must_equal(1)
    _(last_snapshot[0].data_points.size).must_equal(1)
    _(last_snapshot[0].data_points[0].value).must_equal(1)
  end

  it 'separate gauge should record their own last value' do
    gauge.record(-2, attributes: { 'foo' => 'bar' })
    gauge.record(1, attributes: { 'foo' => 'bar' })
    gauge2 = meter.create_gauge('gauge2', unit: 'smidgen', description: 'a small amount of something')
    gauge2.record(10, attributes: {})

    metric_reader.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot.size).must_equal(2)
    _(last_snapshot[0].data_points[0].value).must_equal(1)
    _(last_snapshot[1].data_points[0].value).must_equal(10)
  end
end
