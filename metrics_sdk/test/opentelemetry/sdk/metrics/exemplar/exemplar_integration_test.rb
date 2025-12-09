# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#exemplar_integration_test' do
    before { reset_metrics_sdk }

    it 'emits metrics with list of exemplar' do
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

    it 'emits histogram metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')
      histogram = meter.create_histogram('histogram', unit: 'ms', description: 'response time', exemplar_reservoir: exemplar_reservoir)

      histogram.record(10)
      histogram.record(20, attributes: { 'a' => 'b' })
      histogram.record(30, attributes: { 'a' => 'b' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('histogram')
      _(last_snapshot[0].unit).must_equal('ms')
      _(last_snapshot[0].description).must_equal('response time')

      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_be :>, 0

      _(last_snapshot[0].data_points[1].attributes).must_equal('a' => 'b')
      _(last_snapshot[0].data_points[1].exemplars).must_be_kind_of(Array)
    end

    it 'emits gauge metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')
      gauge = meter.create_gauge('gauge', unit: 'celsius', description: 'temperature', exemplar_reservoir: exemplar_reservoir)

      gauge.record(25)
      gauge.record(28, attributes: { 'location' => 'room1' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('gauge')
      _(last_snapshot[0].unit).must_equal('celsius')
      _(last_snapshot[0].description).must_equal('temperature')

      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_be :>, 0
    end

    it 'emits up_down_counter metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')
      up_down_counter = meter.create_up_down_counter('up_down_counter', unit: 'items', description: 'queue size', exemplar_reservoir: exemplar_reservoir)

      up_down_counter.add(5)
      up_down_counter.add(-2, attributes: { 'queue' => 'main' })
      up_down_counter.add(3, attributes: { 'queue' => 'main' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('up_down_counter')

      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_be :>, 0
    end

    it 'emits observable_counter metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')

      meter.create_observable_counter(
        'observable_counter',
        unit: 'requests',
        description: 'total requests',
        exemplar_reservoir: exemplar_reservoir,
        callback: lambda do |observer|
          observer.observe(100)
          observer.observe(200, attributes: { 'endpoint' => '/api' })
        end
      )

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_counter')

      _(last_snapshot[0].data_points.size).must_be :>, 0
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
    end

    it 'emits observable_gauge metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')

      meter.create_observable_gauge(
        'observable_gauge',
        unit: 'MB',
        description: 'memory usage',
        exemplar_reservoir: exemplar_reservoir,
        callback: lambda do |observer|
          observer.observe(512)
          observer.observe(768, attributes: { 'process' => 'worker' })
        end
      )

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_gauge')

      _(last_snapshot[0].data_points.size).must_be :>, 0
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
    end

    it 'emits observable_up_down_counter metrics with exemplars' do
      ENV['OTEL_METRICS_EXPORTER'] = 'none'

      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      meter = OpenTelemetry.meter_provider.meter('test')

      meter.create_observable_up_down_counter(
        'observable_up_down_counter',
        unit: 'connections',
        description: 'active connections',
        exemplar_reservoir: exemplar_reservoir,
        callback: lambda do |observer|
          observer.observe(50)
          observer.observe(-10, attributes: { 'server' => 'backend' })
        end
      )

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_up_down_counter')

      _(last_snapshot[0].data_points.size).must_be :>, 0
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
    end
  end
end
