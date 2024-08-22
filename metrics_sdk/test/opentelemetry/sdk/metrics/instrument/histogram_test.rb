# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Instrument::Histogram do
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:meter) { OpenTelemetry.meter_provider.meter('test') }
  let(:histogram) { meter.create_histogram('histogram', unit: 'smidgen', description: 'a small amount of something') }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
  end

  it 'histograms' do
    histogram.record(5, attributes: { 'foo' => 'bar' })
    histogram.record(6, attributes: { 'foo' => 'bar' })
    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots.last

    _(last_snapshot[0].name).must_equal('histogram')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].count).must_equal(2)
    _(last_snapshot[0].data_points[0].sum).must_equal(11)
    _(last_snapshot[0].data_points[0].min).must_equal(5)
    _(last_snapshot[0].data_points[0].max).must_equal(6)
    _(last_snapshot[0].data_points[0].bucket_counts).must_equal([0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0])
    _(last_snapshot[0].data_points[0].attributes).must_equal('foo' => 'bar')
    _(last_snapshot[0].aggregation_temporality).must_equal(:delta)
  end

  it 'can apply advice to change the explicit bucket boundaries' do
    histogram = meter.create_histogram('histogram', unit: 's', description: 'test', advice: { explicit_bucket_boundaries: [5, 10, 15] })

    histogram.record(0)
    histogram.record(5)
    histogram.record(5)
    histogram.record(10)
    histogram.record(20)

    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots.last
    _(last_snapshot[0].data_points[0].bucket_counts).must_equal([3, 1, 0, 1])

    _(last_snapshot[0].name).must_equal('histogram')
    _(last_snapshot[0].unit).must_equal('s')
    _(last_snapshot[0].description).must_equal('test')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].count).must_equal(5)
    _(last_snapshot[0].data_points[0].sum).must_equal(40)
    _(last_snapshot[0].data_points[0].min).must_equal(0)
    _(last_snapshot[0].data_points[0].max).must_equal(20)
    _(last_snapshot[0].data_points[0].attributes).must_be_nil
    _(last_snapshot[0].aggregation_temporality).must_equal(:delta)
  end
end
