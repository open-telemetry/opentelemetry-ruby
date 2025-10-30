# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream do
  let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new }
  let(:instrumentation_scope) { OpenTelemetry::SDK::InstrumentationScope.new('test_scope', '1.0.0') }
  let(:aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new }
  let(:callback) { [proc { 42 }] }
  let(:timeout) { 10 }
  let(:attributes) { { 'environment' => 'test' } }
  let(:async_metric_stream) do
    OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
      'async_counter',
      'An async counter',
      'count',
      :observable_counter,
      meter_provider,
      instrumentation_scope,
      aggregation,
      callback,
      timeout,
      attributes
    )
  end

  describe '#initialize' do
    it 'initializes with provided parameters and async-specific attributes' do
      _(async_metric_stream.name).must_equal('async_counter')
      _(async_metric_stream.description).must_equal('An async counter')
      _(async_metric_stream.unit).must_equal('count')
      _(async_metric_stream.instrument_kind).must_equal(:observable_counter)
      _(async_metric_stream.instrumentation_scope).must_equal(instrumentation_scope)
      _(async_metric_stream.data_points).must_be_instance_of(Hash)
      _(async_metric_stream.data_points).must_be_empty

      # Verify async-specific attributes
      _(async_metric_stream.instance_variable_get(:@callback)).must_equal(callback)
      _(async_metric_stream.instance_variable_get(:@timeout)).must_equal(timeout)
      _(async_metric_stream.instance_variable_get(:@start_time)).must_be_instance_of(Integer)
      _(async_metric_stream.instance_variable_get(:@start_time)).must_be :>, 0
    end

    it 'finds and registers matching views during initialization' do
      view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'async_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )
      meter_provider.instance_variable_get(:@registered_views) << view

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback,
        timeout,
        attributes
      )

      registered_views = stream.instance_variable_get(:@registered_views)
      _(registered_views.size).must_equal(1)
      _(registered_views.first[0].aggregation.class).must_equal ::OpenTelemetry::SDK::Metrics::Aggregation::LastValue
    end
  end

  describe '#collect' do
    it 'invokes callback and handles various collection scenarios' do
      # Test basic collection with callback value and attributes
      metric_data_array = async_metric_stream.collect(0, 1000)
      _(metric_data_array).must_be_instance_of(Array)
      _(metric_data_array.size).must_equal(1)

      metric_data = metric_data_array.first
      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(metric_data.name).must_equal('async_counter')
      _(metric_data.start_time_unix_nano).must_equal(0)
      _(metric_data.time_unix_nano).must_equal(1000)
      _(metric_data.data_points.first.value).must_equal(42)
      _(metric_data.data_points.first.attributes).must_equal(attributes)

      # Test empty collection when callback returns nil
      empty_callback = [proc { nil }]
      empty_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        empty_callback, timeout, {}
      )
      _(empty_stream.collect(0, 1000)).must_be_empty

      # Test multiple callbacks accumulation
      multi_callbacks = [proc { 10 }, proc { 20 }, proc { 30 }]
      multi_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        multi_callbacks, timeout, attributes
      )
      multi_result = multi_stream.collect(0, 1000)
      _(multi_result.first.data_points.first.value).must_equal(60) # 10 + 20 + 30
    end

    it 'handles multiple registered views with attribute merging' do
      view1 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'async_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Sum.new
      )
      view2 = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'async_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new,
        attribute_keys: { 'environment' => 'production', 'service' => 'metrics' }
      )

      meter_provider.instance_variable_get(:@registered_views) << view1
      meter_provider.instance_variable_get(:@registered_views) << view2

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        callback, timeout, { 'original' => 'value' }
      )

      metric_data_array = stream.collect(0, 1000)
      _(metric_data_array.size).must_equal(2)

      # Verify view with attribute merging
      view_with_attrs = metric_data_array.find { |md| md.data_points.first.attributes.key?('service') }
      _(view_with_attrs).wont_be_nil
      attrs = view_with_attrs.data_points.first.attributes
      _(attrs['environment']).must_equal('production')
      _(attrs['service']).must_equal('metrics')
      _(attrs['original']).must_equal('value')
    end

    it 'handles callback exceptions' do
      error_callback = [proc { raise StandardError, 'Callback error' }]
      error_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        error_callback, timeout, attributes
      )

      # Capture the logged output
      original_logger = OpenTelemetry.logger
      log_output = StringIO.new
      OpenTelemetry.logger = Logger.new(log_output)
      error_stream.collect(0, 1000)
      sleep 0.5
      assert_includes log_output.string, 'OpenTelemetry error: Error invoking callback.'
      OpenTelemetry.logger = original_logger
    end
  end

  describe '#invoke_callback' do
    it 'executes callbacks with timeout and handles thread safety with multiple callback' do
      # Test multiple callbacks in array
      multi_callbacks = [
        proc { 10 },
        proc { 20 },
        proc { 30 }
      ]
      multi_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        multi_callbacks, timeout, attributes
      )
      multi_stream.invoke_callback(timeout, attributes)

      # Test thread safety
      thread_count = 0
      thread_callback = [proc {
        thread_count += 1
        42
      }]
      thread_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        thread_callback, timeout, attributes
      )

      metric_data = nil
      threads = Array.new(5) do
        # Thread.new { thread_stream.invoke_callback(timeout, attributes) }
        Thread.new { metric_data = thread_stream.collect(0, 10_000) }
      end
      threads.each(&:join)

      _(thread_count).must_equal(5)
      _(metric_data.first.data_points.first.value).must_equal 210
      _(metric_data.first.data_points.first.attributes['environment']).must_equal 'test'
      _(metric_data.first.start_time_unix_nano).must_equal 0
      _(metric_data.first.time_unix_nano).must_equal 10_000
    end
  end

  describe 'aggregation and view integration' do
    it 'supports different aggregation types and accumulation' do
      # Test Sum aggregation accumulation
      callback_value = 100
      callback_proc = [proc { callback_value }]
      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        callback_proc, timeout, attributes
      )

      stream.collect(0, 1000)
      metric_data = stream.collect(1000, 2000)
      _(metric_data.first.data_points.first.value).must_equal 200

      # Test LastValue aggregation
      last_value_aggregation = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_gauge', 'description', 'units', :observable_gauge,
        meter_provider, instrumentation_scope, last_value_aggregation,
        callback_proc, timeout, attributes
      )

      # Calling it twice but last value should preserve last one instead of sum
      stream.collect(0, 1000)
      metric_data = stream.collect(0, 1000)
      _(metric_data.first.data_points.first.value).must_equal 100
    end

    it 'handles view filtering and drop aggregation xuan' do
      # Test view filtering by instrument name (non-matching)
      non_matching_view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'different_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )

      # Test view filtering by instrument type (matching)
      type_matching_view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        nil, type: :observable_counter,
             aggregation: OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      )

      meter_provider.instance_variable_get(:@registered_views) << non_matching_view
      meter_provider.instance_variable_get(:@registered_views) << type_matching_view

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        callback, timeout, attributes
      )

      metric_data = stream.collect(0, 1000)
      _(metric_data.size).must_equal(1) # Should match type-based view

      # Test Drop aggregation
      drop_view = OpenTelemetry::SDK::Metrics::View::RegisteredView.new(
        'async_counter',
        aggregation: OpenTelemetry::SDK::Metrics::Aggregation::Drop.new
      )
      meter_provider.instance_variable_get(:@registered_views).clear
      meter_provider.instance_variable_get(:@registered_views) << drop_view

      drop_stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter', 'description', 'unit', :observable_counter,
        meter_provider, instrumentation_scope, aggregation,
        callback, timeout, attributes
      )

      dropped_data = drop_stream.collect(0, 1000)
      _(dropped_data.size).must_equal(1)
      _(dropped_data.first.data_points.first.value).must_equal(0) # Dropped value
    end
  end
end
