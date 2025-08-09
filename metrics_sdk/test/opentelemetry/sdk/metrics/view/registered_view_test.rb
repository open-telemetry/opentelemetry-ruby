# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::View::RegisteredView do
  describe '#registered_view' do
    before { reset_metrics_sdk }

    it 'emits metrics with no data_points if view is drop' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      OpenTelemetry.meter_provider.add_view('counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Drop.new)

      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2, attributes: { 'a' => 'b' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('counter')
      _(last_snapshot[0].unit).must_equal('smidgen')
      _(last_snapshot[0].description).must_equal('a small amount of something')

      _(last_snapshot[0].instrumentation_scope.name).must_equal('test')

      _(last_snapshot[0].data_points[0].value).must_equal 0
      _(last_snapshot[0].data_points[0].start_time_unix_nano).must_equal 0
      _(last_snapshot[0].data_points[0].time_unix_nano).must_equal 0

      _(last_snapshot[0].data_points[1].value).must_equal 0
      _(last_snapshot[0].data_points[1].start_time_unix_nano).must_equal 0
      _(last_snapshot[0].data_points[1].time_unix_nano).must_equal 0
    end

    it 'emits metrics with only last value in data_points if view is last_value' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      OpenTelemetry.meter_provider.add_view('counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new)

      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2)
      counter.add(3)
      counter.add(4)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot[0].data_points).wont_be_empty
      _(last_snapshot[0].data_points[0].value).must_equal 4
    end

    it 'emits metrics with sum of value in data_points if view is last_value but not matching to instrument' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      OpenTelemetry.meter_provider.add_view('retnuoc', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new)

      counter = meter.create_counter('counter', unit: 'smidgen', description: 'a small amount of something')

      counter.add(1)
      counter.add(2)
      counter.add(3)
      counter.add(4)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot[0].data_points).wont_be_empty
      _(last_snapshot[0].data_points[0].value).must_equal 10
    end
  end

  describe '#registered_view with asynchronous counters' do
    before { reset_metrics_sdk }

    it 'emits asynchronous counter metrics with no data_points if view is drop' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      OpenTelemetry.meter_provider.add_view('async_counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Drop.new)

      callback = proc { 42 }
      meter.create_observable_counter('async_counter', unit: 'smidgen', description: 'an async counter', callback: callback)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot).wont_be_empty
      _(last_snapshot[0].name).must_equal('async_counter')
      _(last_snapshot[0].unit).must_equal('smidgen')
      _(last_snapshot[0].description).must_equal('an async counter')
      _(last_snapshot[0].instrumentation_scope.name).must_equal('test')

      _(last_snapshot[0].data_points[0].value).must_equal 0
      _(last_snapshot[0].data_points[0].start_time_unix_nano).must_equal 0
      _(last_snapshot[0].data_points[0].time_unix_nano).must_equal 0
    end

    it 'emits asynchronous counter metrics with only last value in data_points if view is last_value xuan' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      OpenTelemetry.meter_provider.add_view('async_counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new)

      # Create a callback that returns different values each time it's called
      call_count = 0
      callback = proc do
        call_count += 1
        final_count = call_count * 10
        final_count
      end

      observable_counter = meter.create_observable_counter('async_counter', unit: 'smidgen', description: 'an async counter', callback: callback)

      # Trigger multiple collections to simulate multiple callback invocations
      2.times { observable_counter.observe }
      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot[0].data_points).wont_be_empty
      _(last_snapshot[0].data_points[0].value).must_equal 30
    end

    it 'emits asynchronous counter metrics with sum of values if view is drop but not matching to instrument' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      # View name doesn't match the instrument name
      OpenTelemetry.meter_provider.add_view('retnuoc_cnysa', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Drop.new)

      callback = proc { 15 }
      meter.create_observable_counter('async_counter', unit: 'smidgen', description: 'an async counter', callback: callback)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot[0].data_points).wont_be_empty
      # Since view doesn't match, it should use default aggregation (sum for counters)
      _(last_snapshot[0].data_points[0].value).must_equal 15
    end

    it 'emits asynchronous counter metrics with multiple registered views' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')
      # Add multiple views for the same instrument
      OpenTelemetry.meter_provider.add_view('async_counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Sum.new)
      OpenTelemetry.meter_provider.add_view('async_counter', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new)

      callback = proc { 25 }
      meter.create_observable_counter('async_counter', unit: 'smidgen', description: 'an async counter', callback: callback)

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      # Should have multiple metric data entries (one for each view)
      _(last_snapshot.size).must_be :>=, 2

      # All should have the same instrument metadata
      last_snapshot.each do |snapshot|
        _(snapshot.name).must_equal('async_counter')
        _(snapshot.unit).must_equal('smidgen')
        _(snapshot.description).must_equal('an async counter')
        _(snapshot.instrumentation_scope.name).must_equal('test')
        _(snapshot.data_points).wont_be_empty
      end
    end

    it 'emits asynchronous counter metrics with view attribute filtering' do
      OpenTelemetry::SDK.configure

      metric_exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)

      meter = OpenTelemetry.meter_provider.meter('test')

      # Create a view that adds specific attributes
      view_with_attributes = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'async_counter',
        aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Sum.new,
        attribute_keys: { 'environment' => 'test', 'service' => 'metrics' }
      )
      OpenTelemetry.meter_provider.instance_variable_get(:@registered_views) << view_with_attributes

      callback = proc { 35 }
      observable_counter = meter.create_observable_counter('async_counter', unit: 'smidgen', description: 'an async counter', callback: callback)
      observable_counter.add_attributes({ 'original' => 'value' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots

      _(last_snapshot[0].data_points).wont_be_empty
      _(last_snapshot[0].data_points[0].value).must_equal 35

      # Check that view attributes are merged with original attributes
      attributes = last_snapshot[0].data_points[0].attributes
      _(attributes['environment']).must_equal 'test'
      _(attributes['service']).must_equal 'metrics'
      _(attributes['original']).must_equal 'value'
    end
  end

  describe '#registered_view select instrument' do
    let(:registered_view) { OpenTelemetry::SDK::Metrics::View::RegisteredView.new(nil, aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new) }
    let(:instrumentation_scope) do
      OpenTelemetry::SDK::InstrumentationScope.new('test_scope', '1.0.1')
    end

    let(:metric_stream) do
      OpenTelemetry::SDK::Metrics::State::MetricStream.new('test', 'description', 'smidgen', :counter, nil, instrumentation_scope, nil)
    end

    it 'registered view with matching name' do
      registered_view.instance_variable_set(:@name, 'test')
      registered_view.send(:generate_regex_pattern, 'test')
      _(registered_view.match_instrument?(metric_stream)).must_equal true
    end

    it 'registered view with matching type' do
      registered_view.instance_variable_set(:@options, { type: :counter })
      _(registered_view.match_instrument?(metric_stream)).must_equal true
    end

    it 'registered view with matching version' do
      registered_view.instance_variable_set(:@options, { meter_version: '1.0.1' })
      _(registered_view.match_instrument?(metric_stream)).must_equal true
    end

    it 'registered view with matching meter_name' do
      registered_view.instance_variable_set(:@options, { meter_name: 'test_scope' })
      _(registered_view.match_instrument?(metric_stream)).must_equal true
    end

    it 'do not registered view with unmatching name and matching type' do
      registered_view.instance_variable_set(:@options, { type: :counter })
      registered_view.instance_variable_set(:@name, 'tset')
      _(registered_view.match_instrument?(metric_stream)).must_equal false
    end

    describe '#name_match' do
      it 'name_match_for_wild_card' do
        registered_view.instance_variable_set(:@name, 'log*2024?.txt')
        registered_view.send(:generate_regex_pattern, 'log*2024?.txt')
        _(registered_view.name_match('logfile20242.txt')).must_equal true
        _(registered_view.name_match('log2024a.txt')).must_equal true
        _(registered_view.name_match('log_test_2024.txt')).must_equal false
      end

      it 'name_match_for_*' do
        registered_view.instance_variable_set(:@name, '*')
        registered_view.send(:generate_regex_pattern, '*')
        _(registered_view.name_match('*')).must_equal true
        _(registered_view.name_match('aaaaaaaaa')).must_equal true
        _(registered_view.name_match('!@#$%^&')).must_equal true
      end
    end
  end
end
