# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Instrument::ExponentialHistogram do
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:meter) { OpenTelemetry.meter_provider.meter('test') }
  let(:exponential_histogram) { meter.create_exponential_histogram('exponential_histogram', unit: 'smidgen', description: 'a small amount of something') }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
  end

  it 'expotential histograms' do
    exponential_histogram.record(5, attributes: { 'foo' => 'bar' })
    exponential_histogram.record(6, attributes: { 'foo' => 'bar' })
    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot[0].name).must_equal('exponential_histogram')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].count).must_equal(2)
    _(last_snapshot[0].data_points[0].sum).must_equal(11)
    _(last_snapshot[0].data_points[0].min).must_equal(5)
    _(last_snapshot[0].data_points[0].max).must_equal(6)
    _(last_snapshot[0].data_points[0].scale).must_equal(9)
    _(last_snapshot[0].data_points[0].zero_count).must_equal(0)
    _(last_snapshot[0].data_points[0].positive.offset).must_equal(1188)
    _(last_snapshot[0].data_points[0].positive.counts).must_equal([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    _(last_snapshot[0].data_points[0].negative.offset).must_equal(0)
    _(last_snapshot[0].data_points[0].negative.counts).must_equal([0])
    _(last_snapshot[0].data_points[0].flags).must_equal(0)
    _(last_snapshot[0].data_points[0].zero_threshold).must_equal(0)
    _(last_snapshot[0].aggregation_temporality).must_equal(:delta)
  end
end
