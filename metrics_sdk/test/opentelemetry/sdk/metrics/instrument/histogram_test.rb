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
    last_snapshot = metric_exporter.metric_snapshots

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

  describe 'with advisory parameters' do
    let(:explicit_bucket_boundaries) { [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5, 10] }
    let(:histogram) do
      meter.create_histogram(
        'histogram',
        unit: 'smidgen',
        description: 'a small amount of something',
        explicit_bucket_boundaries: explicit_bucket_boundaries,
        attributes: { random_attribute => true }
      )
    end

    let(:random_attribute) { "a#{SecureRandom.hex}" }

    it 'histograms' do
      histogram.record(0.01)
      histogram.record(0.1, attributes: { 'foo' => 'bar' })
      histogram.record(1)
      histogram.record(10)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots.last

      _(last_snapshot.data_points.count).must_equal(2)

      last_snapshot.data_points.each do |data_point|
        _(data_point.attributes[random_attribute]).must_equal(true)
      end

      _(last_snapshot.data_points.first.bucket_counts).must_equal(
        [0, 0, 1, 0, 0, 0, 1, 0, 1, 0]
      )

      _(last_snapshot.data_points.last.bucket_counts).must_equal(
        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0]
      )
    end
  end
end
