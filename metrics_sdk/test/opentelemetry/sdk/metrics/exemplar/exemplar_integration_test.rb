# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#exempler_integration_test' do
    before { reset_metrics_sdk }

    it 'emits metrics with list of exempler' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something', exemplar_reservoir: exemplar_reservoir)

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

      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].class).must_equal OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].span_id).must_equal '0000000000000000'
      _(last_snapshot[0].data_points[0].exemplars[0].trace_id).must_equal '00000000000000000000000000000000'
    end
  end
end
