# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#exemplar_integration_test' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
    let(:meter) { OpenTelemetry.meter_provider.meter('test') }

    before do
      reset_metrics_sdk
      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)
    end

    it 'emits metrics with list of exemplar' do
      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(2, attributes: { 'a' => 'b' })
      counter.add(3, attributes: { 'b' => 'c' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('counter')
      _(last_snapshot[0].unit).must_equal('smidgen')
      _(last_snapshot[0].description).must_equal('a small amount of something')
      _(last_snapshot[0].instrumentation_scope.name).must_equal('test')

      # Verify data points and their exemplars
      _(last_snapshot[0].data_points.size).must_equal 3

      # First data point: {} attributes, value=1, 1 exemplar
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].value).must_equal(1)
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0]).must_be_kind_of OpenTelemetry::SDK::Metrics::Exemplar::Exemplar

      # Second data point: {'a' => 'b'} attributes, value=4, 2 exemplars
      _(last_snapshot[0].data_points[1].attributes).must_equal('a' => 'b')
      _(last_snapshot[0].data_points[1].value).must_equal(4)
      _(last_snapshot[0].data_points[1].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[1].exemplars[0].value).must_equal 2
      _(last_snapshot[0].data_points[1].exemplars[1].value).must_equal 2

      # Third data point: {'b' => 'c'} attributes, value=3, 1 exemplar
      _(last_snapshot[0].data_points[2].attributes).must_equal('b' => 'c')
      _(last_snapshot[0].data_points[2].value).must_equal(3)
      _(last_snapshot[0].data_points[2].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[2].exemplars[0].value).must_equal 3
    end

    it 'emits histogram metrics with exemplars' do
      histogram = meter.create_histogram('histogram', unit: 'ms', description: 'response time')

      histogram.record(10)
      histogram.record(20, attributes: { 'a' => 'b' })
      histogram.record(30, attributes: { 'a' => 'b' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('histogram')
      _(last_snapshot[0].unit).must_equal('ms')
      _(last_snapshot[0].description).must_equal('response time')

      # First data point: {} attributes, count=1, sum=10, 1 exemplar with value 10
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].count).must_equal 1
      _(last_snapshot[0].data_points[0].sum).must_equal 10
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 10

      # Second data point: {'a' => 'b'} attributes, count=2, sum=50, 2 exemplars with values 20 and 30
      _(last_snapshot[0].data_points[1].attributes).must_equal('a' => 'b')
      _(last_snapshot[0].data_points[1].count).must_equal 2
      _(last_snapshot[0].data_points[1].sum).must_equal 50
      _(last_snapshot[0].data_points[1].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[1].exemplars[0].value).must_equal 20
      _(last_snapshot[0].data_points[1].exemplars[1].value).must_equal 30
    end

    it 'emits gauge metrics with exemplars' do
      gauge = meter.create_gauge('gauge', unit: 'celsius', description: 'temperature')

      gauge.record(25)
      gauge.record(28, attributes: { 'location' => 'room1' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('gauge')
      _(last_snapshot[0].unit).must_equal('celsius')
      _(last_snapshot[0].description).must_equal('temperature')
      _(last_snapshot[0].data_points.size).must_equal 2

      # First data point: {} attributes, value=25, 1 exemplar with value 25
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].value).must_equal 25
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 25

      # Second data point: {'location' => 'room1'} attributes, value=28, 1 exemplar with value 28
      _(last_snapshot[0].data_points[1].attributes).must_equal('location' => 'room1')
      _(last_snapshot[0].data_points[1].value).must_equal 28
      _(last_snapshot[0].data_points[1].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[1].exemplars[0].value).must_equal 28
    end

    it 'emits up_down_counter metrics with exemplars' do
      up_down_counter = meter.create_up_down_counter('up_down_counter', unit: 'items', description: 'queue size')

      up_down_counter.add(5)
      up_down_counter.add(-2, attributes: { 'queue' => 'main' })
      up_down_counter.add(3, attributes: { 'queue' => 'main' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('up_down_counter')
      _(last_snapshot[0].data_points.size).must_equal 2

      # First data point: {} attributes, value=5, 1 exemplar with value 5
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].value).must_equal 5
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 1
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 5

      # Second data point: {'queue' => 'main'} attributes, value=1, 2 exemplars with values -2 and 3
      _(last_snapshot[0].data_points[1].attributes).must_equal('queue' => 'main')
      _(last_snapshot[0].data_points[1].value).must_equal 1
      _(last_snapshot[0].data_points[1].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[1].exemplars[0].value).must_equal(-2)
      _(last_snapshot[0].data_points[1].exemplars[1].value).must_equal 3
    end

    it 'emits observable_counter metrics with exemplars' do
      counter = meter.create_observable_counter(
        'observable_counter',
        unit: 'requests',
        description: 'total requests',
        callback: lambda do
          100
        end
      )

      counter.observe

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_counter')
      _(last_snapshot[0].data_points.size).must_equal 1

      # Observable counter observes twice, resulting in 2 exemplars
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 100
      _(last_snapshot[0].data_points[0].exemplars[1].value).must_equal 100
    end

    it 'emits observable_gauge metrics with exemplars' do
      gauge = meter.create_observable_gauge(
        'observable_gauge',
        unit: 'Objects',
        description: 'Object Slots',
        callback: lambda do
          100
        end
      )

      gauge.observe

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_gauge')
      _(last_snapshot[0].data_points.size).must_equal 1

      # Observable gauge observes twice, resulting in 2 exemplars with GC stats
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 100
      _(last_snapshot[0].data_points[0].exemplars[1].value).must_equal 100
    end

    it 'emits observable_up_down_counter metrics with exemplars' do
      counter = meter.create_observable_up_down_counter(
        'observable_up_down_counter',
        unit: 'connections',
        description: 'active connections',
        callback: lambda do
          50
        end
      )

      counter.observe

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('observable_up_down_counter')
      _(last_snapshot[0].data_points.size).must_equal 1

      # Observable up_down_counter observes twice, resulting in 2 exemplars
      _(last_snapshot[0].data_points[0].attributes).must_equal({})
      _(last_snapshot[0].data_points[0].exemplars).must_be_kind_of(Array)
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 2
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 50
      _(last_snapshot[0].data_points[0].exemplars[1].value).must_equal 50
    end

    it 'emits exponential bucket histogram metrics with exemplars' do
      reset_metrics_sdk
      meter = create_meter
      OpenTelemetry.meter_provider.add_view(
        'exponential_histogram',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(exemplar_reservoir: OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 4))
      )
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      histogram = meter.create_histogram('exponential_histogram', unit: 'bytes', description: 'data size')

      histogram.record(100)
      histogram.record(200, attributes: { 'type' => 'upload' })
      histogram.record(400, attributes: { 'type' => 'upload' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty

      exponential_histogram = last_snapshot.first
      _(exponential_histogram.name).must_equal('exponential_histogram')
      _(exponential_histogram.unit).must_equal('bytes')
      _(exponential_histogram.description).must_equal('data size')
      _(exponential_histogram.data_points.size).must_equal 2

      # First data point: {} attributes, count=1, sum=100, 2 exemplars
      _(exponential_histogram.data_points[0].attributes).must_equal({})
      _(exponential_histogram.data_points[0].count).must_equal 1
      _(exponential_histogram.data_points[0].sum).must_equal 100
      _(exponential_histogram.data_points[0].scale).must_equal 20
      _(exponential_histogram.data_points[0].exemplars.size).must_equal 2

      # Second data point: {'type' => 'upload'} attributes, count=2, sum=600, 4 exemplars
      _(exponential_histogram.data_points[1].attributes).must_equal('type' => 'upload')
      _(exponential_histogram.data_points[1].count).must_equal 2
      _(exponential_histogram.data_points[1].sum).must_equal 600
      _(exponential_histogram.data_points[1].scale).must_equal 7
      _(exponential_histogram.data_points[1].exemplars.size).must_equal 4
      _(exponential_histogram.data_points[1].exemplars.map(&:value).sort).must_equal [200, 200, 400, 400]
    end

    it 'emits counter metrics with exemplars and customized reservoir' do
      # Create counter with customized SimpleFixedSizeExemplarReservoir (max_size=2)
      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 2)
      counter = meter.create_counter('custom_counter', unit: 'operations', description: 'operations with custom reservoir', exemplar_reservoir: exemplar_reservoir)

      # Add multiple values - reservoir should sample due to size limit
      counter.add(10, attributes: { 'operation' => 'read' })
      counter.add(20, attributes: { 'operation' => 'read' })
      counter.add(30, attributes: { 'operation' => 'read' })
      counter.add(40, attributes: { 'operation' => 'read' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('custom_counter')
      _(last_snapshot[0].unit).must_equal('operations')
      _(last_snapshot[0].description).must_equal('operations with custom reservoir')

      # With max_size=2, reservoir should contain at most 2 exemplars per data point
      _(last_snapshot[0].data_points.size).must_equal 1
      _(last_snapshot[0].data_points[0].attributes).must_equal('operation' => 'read')
      _(last_snapshot[0].data_points[0].value).must_equal 100
      _(last_snapshot[0].data_points[0].exemplars.size).must_be :<=, 2

      # Verify exemplars contain valid values from the adds
      exemplar_values = last_snapshot[0].data_points[0].exemplars.map(&:value)
      exemplar_values.each do |value|
        _([10, 20, 30, 40]).must_include value
      end
    end

    it 'emits counter metrics with exemplars across multiple views' do
      reset_metrics_sdk
      meter = create_meter

      # Add multiple views for the same counter
      OpenTelemetry.meter_provider.add_view(
        'request_counter',
        name: 'request_counter_view1',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(exemplar_reservoir: OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 4))
      )
      OpenTelemetry.meter_provider.add_view(
        'request_counter',
        name: 'request_counter_view2',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new(exemplar_reservoir: OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 4))
      )

      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
      OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter)

      exemplar_reservoir = OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
      counter = meter.create_counter('request_counter', unit: 'requests', description: 'total requests', exemplar_reservoir: exemplar_reservoir)

      counter.add(10, attributes: { 'status' => '200' })
      counter.add(20, attributes: { 'status' => '200' })
      counter.add(3, attributes: { 'status' => '500' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot.size).must_equal 4

      # All metrics should have the same metadata
      last_snapshot.each do |metric|
        _(metric.name).must_equal 'request_counter'
        _(metric.description).must_equal 'total requests'
        _(metric.unit).must_equal 'requests'
        _(metric.data_points.size).must_equal 2
      end

      # First 2 metrics have exemplars populated (one for each view)
      metrics_with_exemplars = last_snapshot[0..1]

      # First metric (Sum aggregation): status='200' value=30, status='500' value=3
      sum_metric = metrics_with_exemplars.find { |m| m.aggregation_temporality == :cumulative }
      _(sum_metric).wont_be_nil

      sum200 = sum_metric.data_points.find { |dp| dp.attributes['status'] == '200' }
      _(sum200.value).must_equal 30 # 10 + 20
      _(sum200.exemplars.size).must_equal 4
      _(sum200.exemplars.map(&:value)).must_equal [10, 10, 20, 20]

      sum500 = sum_metric.data_points.find { |dp| dp.attributes['status'] == '500' }
      _(sum500.value).must_equal 3
      _(sum500.exemplars.size).must_equal 2
      _(sum500.exemplars.map(&:value)).must_equal [3, 3]

      # Second metric (LastValue aggregation): status='200' value=20, status='500' value=3
      lastvalue_metric = metrics_with_exemplars.find { |m| m.aggregation_temporality.nil? }
      _(lastvalue_metric).wont_be_nil

      lastvalue200 = lastvalue_metric.data_points.find { |dp| dp.attributes['status'] == '200' }
      _(lastvalue200.value).must_equal 20 # Last value
      _(lastvalue200.exemplars.size).must_equal 4
      _(lastvalue200.exemplars.map(&:value)).must_equal [10, 10, 20, 20]

      lastvalue500 = lastvalue_metric.data_points.find { |dp| dp.attributes['status'] == '500' }
      _(lastvalue500.value).must_equal 3
      _(lastvalue500.exemplars.size).must_equal 2
      _(lastvalue500.exemplars.map(&:value)).must_equal [3, 3]

      # Verify all exemplars are properly formed
      metrics_with_exemplars.each do |metric|
        metric.data_points.each do |dp|
          dp.exemplars.each do |exemplar|
            _(exemplar).must_be_kind_of OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
            _(exemplar.filtered_attributes).must_equal({})
          end
        end
      end
    end
  end
end
