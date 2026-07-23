# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Instrument::Counter do
  let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
  let(:meter) { OpenTelemetry.meter_provider.meter('test') }
  let(:counter) { meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something') }

  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
    OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
  end

  it 'counts' do
    counter.add(1, attributes: { 'foo' => 'bar' })
    metric_exporter.pull
    last_snapshot = metric_exporter.metric_snapshots

    _(last_snapshot[0].name).must_equal('counter')
    _(last_snapshot[0].unit).must_equal('smidgen')
    _(last_snapshot[0].description).must_equal('a small amount of something')
    _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
    _(last_snapshot[0].data_points[0].value).must_equal(1)
    _(last_snapshot[0].data_points[0].attributes).must_equal('foo' => 'bar')
    _(last_snapshot[0].aggregation_temporality).must_equal(:cumulative)
  end

  it 'normalizes valid UTF-8 bytes in attributes' do
    city = 'Montréal'.dup.force_encoding(::Encoding::ASCII_8BIT)

    counter.add(1, attributes: { 'city' => city })
    metric_exporter.pull
    value = metric_exporter.metric_snapshots[0].data_points[0].attributes['city']

    _(value).must_equal('Montréal')
    _(value.encoding).must_equal(::Encoding::UTF_8)
    _(city.encoding).must_equal(::Encoding::ASCII_8BIT)
  end

  it 'drops attributes that are not valid UTF-8' do
    invalid = "\xC3".dup.force_encoding(::Encoding::ASCII_8BIT)

    OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
      counter.add(1, attributes: { 'invalid' => invalid })
      metric_exporter.pull

      _(metric_exporter.metric_snapshots[0].data_points[0].attributes).must_be_empty
      _(log_stream.string).must_match(/invalid UTF-8 encoding.*invalid.*Dropping attribute/)
    end
  end
end
