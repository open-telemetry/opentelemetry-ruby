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
