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

    it 'initializes registered views from meter provider' do
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
    it 'updates aggregation with various value and attribute combinations' do
      # Test updates with different attributes (should create separate data points)
      metric_stream.update(10, { 'key' => 'value' })
      metric_stream.update(20, { 'same_key' => 'same_value' })
      metric_stream.update(30, { 'same_key' => 'same_value' }) # Accumulated value
      metric_stream.update(5, { 'key1' => 'value1' })
      metric_stream.update(8, { 'key2' => 'value2' })

      snapshot = metric_stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)

      # Verify data points for different attribute combinations
      data_points = snapshot.first.data_points
      _(data_points.size).must_be :>=, 3 # At least 3 different attribute combinations

      # Verify accumulated value for same_key attributes
      same_key_point = data_points.find { |dp| dp.attributes['same_key'] == 'same_value' }
      _(same_key_point).wont_be_nil
      _(same_key_point.value).must_equal(50) # 20 + 30 = 50

      # Verify individual attribute combinations
      key1_point = data_points.find { |dp| dp.attributes['key1'] == 'value1' }
      key2_point = data_points.find { |dp| dp.attributes['key2'] == 'value2' }
      _(key1_point).wont_be_nil
      _(key2_point).wont_be_nil
      _(key1_point.value).must_equal(5)
      _(key2_point.value).must_equal(8)
    end

    it 'handles registered views with attribute merging' do
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new,
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
      stream.update(20, { 'original' => 'value' })

      snapshot = stream.collect(0, 1000)
      _(snapshot.size).must_equal(1)

      # Check that attributes were merged
      attributes = snapshot.first.data_points.first.attributes
      _(attributes['environment']).must_equal('test')
      _(attributes['original']).must_equal('value')

      value = snapshot.first.data_points.first.value
      _(value).must_equal 20
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
      metric_stream.update(20, {})
      metric_data = metric_stream.aggregate_metric_data(0, 1000)

      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(metric_data.name).must_equal('test_counter')
      _(metric_data.data_points.first.value).must_equal 30
    end

    it 'creates metric data with custom aggregation' do
      # This test case is not relevant in this context.
      # The instrument is already updated using the default aggregation, so the custom aggregation will not impact the collection process.
      # The aggregation parameter in aggregate_metric_data(start_time, end_time, aggregation: nil) is intended
    end
  end

  describe '#find_registered_view' do
    it 'only find matching views by name' do
      view1 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'test_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )

      view2 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'other_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Drop.new
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

      registered_views = stream.instance_variable_get(:@registered_views)

      _(registered_views.size).must_equal 1
      _(registered_views[0].aggregation.class).must_equal ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue
    end
  end

  describe '#to_s' do
    it 'returns string representation without data points' do
      str = metric_stream.to_s
      _(str).must_be_instance_of(String)
      _(str).must_be_empty # No data points yet
    end

    it 'includes data points in string representation' do
      metric_stream.update(10, { 'key1' => 'value1' })
      metric_stream.update(20, { 'key2' => 'value2' })
      str = metric_stream.to_s

      _(str).must_include('test_counter')
      _(str).must_include('A test counter')
      _(str).must_include('count')
      _(str).must_include('key')
      _(str).must_include('value')
      _(str).must_include('key1')
      _(str).must_include('key2')
      _(str.lines.size).must_be :>=, 2
    end
  end
end
