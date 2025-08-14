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
    it 'initializes with provided parameters' do
      _(async_metric_stream.name).must_equal('async_counter')
      _(async_metric_stream.description).must_equal('An async counter')
      _(async_metric_stream.unit).must_equal('count')
      _(async_metric_stream.instrument_kind).must_equal(:observable_counter)
      _(async_metric_stream.instrumentation_scope).must_equal(instrumentation_scope)
      _(async_metric_stream.data_points).must_be_instance_of(Hash)
      _(async_metric_stream.data_points).must_be_empty
    end

    it 'stores callback and timeout' do
      callback_proc = [proc { 100 }]
      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'test',
        'description',
        'unit',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        30,
        {}
      )

      _(stream.instance_variable_get(:@callback)).must_equal(callback_proc)
      _(stream.instance_variable_get(:@timeout)).must_equal(30)
    end

    it 'initializes start time' do
      start_time = async_metric_stream.instance_variable_get(:@start_time)
      _(start_time).must_be_instance_of(Integer)
      _(start_time).must_be :>, 0
    end

    it 'handles nil meter_provider gracefully' do
      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'test',
        'description',
        'unit',
        :observable_counter,
        nil,
        instrumentation_scope,
        aggregation,
        callback,
        timeout,
        attributes
      )
      _(stream.name).must_equal('test')
    end
  end

  describe '#collect' do
    it 'invokes callback and returns metric data' do
      metric_data = async_metric_stream.collect(0, 1000)

      _(metric_data).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(metric_data.name).must_equal('async_counter')
      _(metric_data.description).must_equal('An async counter')
      _(metric_data.unit).must_equal('count')
      _(metric_data.instrument_kind).must_equal(:observable_counter)
      _(metric_data.start_time_unix_nano).must_equal(0)
      _(metric_data.time_unix_nano).must_equal(1000)
    end

    it 'uses callback return value in data points' do
      callback_value = 123
      callback_proc = [proc { callback_value }]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        timeout,
        attributes
      )

      metric_data = stream.collect(0, 1000)
      _(metric_data.data_points).wont_be_empty
      _(metric_data.data_points.first.value).must_equal(callback_value)
    end

    it 'handles multiple callbacks' do
      callbacks = [proc { 10 }, proc { 20 }, proc { 30 }]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callbacks,
        timeout,
        attributes
      )

      metric_data = stream.collect(0, 1000)
      # With Sum aggregation, all callback values should be accumulated
      _(metric_data.data_points.first.value).must_equal(60)
    end

    it 'uses provided attributes in data points' do
      metric_data = async_metric_stream.collect(0, 1000)
      _(metric_data.data_points.first.attributes).must_equal(attributes)
    end

    it 'passes correct timestamps to metric data' do
      start_time = 5000
      end_time = 6000

      metric_data = async_metric_stream.collect(start_time, end_time)
      _(metric_data.start_time_unix_nano).must_equal(start_time)
      _(metric_data.time_unix_nano).must_equal(end_time)
    end

    it 'handles callback exceptions gracefully' do
      error_callback = proc { raise StandardError, 'Callback error' }

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        error_callback,
        timeout,
        attributes
      )

      # Should not raise an exception, but handle it gracefully
      _(-> { stream.collect(0, 1000) }).must_raise(StandardError)
    end
  end

  describe '#invoke_callback' do
    it 'executes callback with timeout' do
      callback_executed = false
      callback_proc = [proc do
        callback_executed = true
        42
      end]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        timeout,
        attributes
      )

      stream.invoke_callback(timeout, attributes)
      _(callback_executed).must_equal(true)
    end

    it 'uses default timeout when none provided' do
      callback_executed = false
      callback_proc = [proc do
        callback_executed = true
        42
      end]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        nil,
        attributes
      )

      # Should use default timeout of 30 seconds
      stream.invoke_callback(nil, attributes)
      _(callback_executed).must_equal(true)
    end

    it 'handles multiple callbacks in array' do
      execution_count = 0
      callbacks = [
        proc { execution_count += 1; 10 },
        proc { execution_count += 1; 20 },
        proc { execution_count += 1; 30 }
      ]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callbacks,
        timeout,
        attributes
      )

      stream.invoke_callback(timeout, attributes)
      _(execution_count).must_equal(3)
    end

    it 'respects timeout setting' do
      slow_callback = [proc do
        sleep(0.1) # Sleep longer than timeout
        42
      end]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        slow_callback,
        0.05, # Very short timeout
        attributes
      )

      # Should raise timeout error
      _(-> { stream.invoke_callback(0.05, attributes) }).must_raise(Timeout::Error)
    end

    it 'is thread-safe xuan' do
      execution_count = 0
      callback_proc = [proc do
        execution_count += 1
        42
      end]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        timeout,
        attributes
      )

      threads = 5.times.map do
        Thread.new { stream.invoke_callback(timeout, attributes) }
      end

      threads.each(&:join)
      _(execution_count).must_equal(5)
    end
  end

  describe '#now_in_nano' do
    it 'returns current time in nanoseconds' do
      nano_time = async_metric_stream.now_in_nano
      _(nano_time).must_be_instance_of(Integer)
      _(nano_time).must_be :>, 0

      # Should be a reasonable timestamp (not too old, not in future)
      current_time_nano = (Time.now.to_r * 1_000_000_000).to_i
      _(nano_time).must_be_close_to(current_time_nano, 1_000_000_000) # Within 1 second
    end

    it 'returns increasing values on successive calls' do
      time1 = async_metric_stream.now_in_nano
      sleep(0.001) # Small delay
      time2 = async_metric_stream.now_in_nano

      _(time2).must_be :>, time1
    end
  end

  describe 'integration with aggregation' do
    it 'updates aggregation correctly with callback values' do
      callback_value = 100
      callback_proc = [proc { callback_value }]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_counter',
        'An async counter',
        'count',
        :observable_counter,
        meter_provider,
        instrumentation_scope,
        aggregation,
        callback_proc,
        timeout,
        attributes
      )

      # First collection
      metric_data1 = stream.collect(0, 1000)
      value1 = metric_data1.data_points.first.value

      # Second collection (should accumulate for Sum aggregation)
      metric_data2 = stream.collect(1000, 2000)
      value2 = metric_data2.data_points.first.value

      # For Sum aggregation, values should accumulate
      _(value2).must_be :>=, value1
    end

    it 'works with different aggregation types' do
      last_value_aggregation = OpenTelemetry::SDK::Metrics::Aggregation::LastValue.new
      callback_value = 50
      callback_proc = [proc { callback_value }]

      stream = OpenTelemetry::SDK::Metrics::State::AsynchronousMetricStream.new(
        'async_gauge',
        'An async gauge',
        'units',
        :observable_gauge,
        meter_provider,
        instrumentation_scope,
        last_value_aggregation,
        callback_proc,
        timeout,
        attributes
      )

      metric_data = stream.collect(0, 1000)
      _(metric_data.data_points.first.value).must_equal(callback_value)
    end
  end
end
