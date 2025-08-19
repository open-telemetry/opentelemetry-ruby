# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge do
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:meter) { OpenTelemetry.meter_provider.meter('test') }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
  end

  it 'counts without observe' do
    callback = proc { 10 }
    meter.create_observable_gauge('gauge', unit: 'smidgen', description: 'a small amount of something', callback: callback)

    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot[0].name).must_equal('gauge')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].value).must_equal(10)
    _(last_snapshot[0].data_points[0].attributes).must_equal({})
  end

  it 'counts with observe' do
    callback = proc { 10 }
    observable_gauge = meter.create_observable_gauge('gauge', unit: 'smidgen', description: 'a small amount of something', callback: callback)
    observable_gauge.observe(timeout: 10, attributes: { 'foo' => 'bar' })

    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot[0].name).must_equal('gauge')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].value).must_equal(10)
    _(last_snapshot[0].data_points[0].attributes).must_equal('foo' => 'bar')

    _(last_snapshot[0].data_points[1].value).must_equal(10)
    _(last_snapshot[0].data_points[1].attributes).must_equal({})
  end
end
