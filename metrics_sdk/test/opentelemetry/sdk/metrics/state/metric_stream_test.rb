# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::State::MetricStream do
  let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new }
  let(:instrumentation_scope) { OpenTelemetry::SDK::InstrumentationScope.new('test_scope', '1.0.0') }
  let(:aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new }
  let(:metric_stream) do
    OpenTelemetry::SDK::Metrics::State::MetricStream.new(
      'test_counter',
      'A test counter',
      'count',
      :counter,
      meter_provider,
      instrumentation_scope,
      aggregation
    )
  end

  describe '#initialize' do
    it 'initializes with provided parameters' do
      _(metric_stream.name).must_equal('test_counter')
      _(metric_stream.description).must_equal('A test counter')
      _(metric_stream.unit).must_equal('count')
      _(metric_stream.instrument_kind).must_equal(:counter)
      _(metric_stream.instrumentation_scope).must_equal(instrumentation_scope)
      _(metric_stream.data_points).must_be_instance_of(Hash)
      _(metric_stream.data_points).must_be_empty
    end

    it 'handles nil meter_provider gracefully' do
      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test',
        'description',
        'unit',
        :counter,
        nil,
        instrumentation_scope,
        aggregation
      )
      _(stream.name).must_equal('test')
    end

    it 'initializes registered views from meter provider' do
      # Create a view that matches our metric stream
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )
      meter_provider.instance_variable_get(:@registered_views) << view

      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      registered_views = stream.instance_variable_get(:@registered_views)
      _(registered_views.size).must_equal(1)
      _(registered_views.first).must_equal(view)
    end
  end

  describe '#update' do
    it 'updates aggregation with value and attributes' do
      metric_stream.update(10, { 'key' => 'value' })
      _(metric_stream.data_points).wont_be_empty
    end

    it 'handles nil attributes' do
      metric_stream.update(10, nil)
      _(metric_stream.data_points).wont_be_empty
    end

    it 'updates multiple times with same attributes' do
      metric_stream.update(10, { 'key' => 'value' })
      metric_stream.update(20, { 'key' => 'value' })

      # Should accumulate values for sum aggregation
      snapshot = metric_stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)
      _(snapshot.first.data_points.first.value).must_equal(30)
    end

    it 'updates with different attributes' do
      metric_stream.update(10, { 'key1' => 'value1' })
      metric_stream.update(20, { 'key2' => 'value2' })

      snapshot = metric_stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)
      _(snapshot.first.data_points.size).must_equal(2)
    end

    it 'handles registered views with attribute merging' do
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Sum.new,
        attribute_keys: { 'environment' => 'test' }
      )
      meter_provider.instance_variable_get(:@registered_views) << view

      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      stream.update(10, { 'original' => 'value' })

      snapshot = stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)

      # Check that attributes were merged
      attributes = snapshot.first.data_points.first.attributes
      _(attributes['environment']).must_equal('test')
      _(attributes['original']).must_equal('value')
    end

    it 'is thread-safe' do
      threads = 10.times.map do |i|
        Thread.new do
          10.times { metric_stream.update(1, { 'thread' => i.to_s }) }
        end
      end

      threads.each(&:join)

      snapshot = metric_stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)
      # With 10 threads each adding 10 times, and 10 different attribute sets
      _(snapshot.first.data_points.size).must_equal(10)
    end
  end

  describe '#collect' do
    it 'returns empty array when no data points' do
      snapshot = metric_stream.collect(0, 1000)
      _(snapshot).must_be_instance_of(Array)
      _(snapshot).must_be_empty
    end

    it 'returns metric data when data points exist' do
      metric_stream.update(10, { 'key' => 'value' })
      snapshot = metric_stream.collect(0, 1000)

      _(snapshot.size).must_equal(1)
      metric_data = snapshot.first
      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(metric_data.name).must_equal('test_counter')
      _(metric_data.description).must_equal('A test counter')
      _(metric_data.unit).must_equal('count')
      _(metric_data.instrument_kind).must_equal(:counter)
    end

    it 'handles multiple registered views' do
      view1 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      )
      view2 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )

      meter_provider.instance_variable_get(:@registered_views) << view1
      meter_provider.instance_variable_get(:@registered_views) << view2

      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      stream.update(10, {})
      snapshot = stream.collect(0, 1000)

      # Should have one metric data per view
      _(snapshot.size).must_equal(2)
    end

    it 'passes correct timestamps to metric data' do
      metric_stream.update(10, {})
      start_time = 1000
      end_time = 2000

      snapshot = metric_stream.collect(start_time, end_time)
      metric_data = snapshot.first

      _(metric_data.start_time_unix_nano).must_equal(start_time)
      _(metric_data.time_unix_nano).must_equal(end_time)
    end
  end

  describe '#aggregate_metric_data' do
    it 'creates metric data with default aggregation' do
      metric_stream.update(10, {})
      metric_data = metric_stream.aggregate_metric_data(0, 1000)

      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(metric_data.name).must_equal('test_counter')
    end

    it 'creates metric data with custom aggregation' do
      metric_stream.update(10, {})
      custom_aggregation = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      metric_data = metric_stream.aggregate_metric_data(0, 1000, aggregation: custom_aggregation)

      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
    end

    it 'handles monotonic aggregations' do
      metric_stream.update(10, {})
      # Sum aggregation should be monotonic for counters
      metric_data = metric_stream.aggregate_metric_data(0, 1000)

      # Check that is_monotonic is set correctly (this depends on aggregation implementation)
      _(metric_data.is_monotonic).wont_be_nil
    end
  end

  describe '#find_registered_view' do
    it 'finds matching views by name' do
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )
      meter_provider.instance_variable_get(:@registered_views) << view

      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      registered_views = stream.instance_variable_get(:@registered_views)
      _(registered_views).must_include(view)
    end

    it 'ignores non-matching views' do
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'other_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )
      meter_provider.instance_variable_get(:@registered_views) << view

      stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      registered_views = stream.instance_variable_get(:@registered_views)
      _(registered_views).wont_include(view)
    end
  end

  describe '#to_s' do
    it 'returns string representation without data points' do
      str = metric_stream.to_s
      _(str).must_be_instance_of(String)
      _(str).must_be_empty # No data points yet
    end

    it 'includes data points in string representation' do
      metric_stream.update(10, { 'key' => 'value' })
      str = metric_stream.to_s

      _(str).must_include('test_counter')
      _(str).must_include('A test counter')
      _(str).must_include('count')
      _(str).must_include('key')
      _(str).must_include('value')
    end

    it 'handles multiple data points' do
      metric_stream.update(10, { 'key1' => 'value1' })
      metric_stream.update(20, { 'key2' => 'value2' })
      str = metric_stream.to_s

      _(str).must_include('key1')
      _(str).must_include('key2')
      _(str.lines.size).must_be :>=, 2
    end
  end
end
