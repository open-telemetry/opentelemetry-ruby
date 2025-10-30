# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::State::MetricStore do
  let(:metric_store) { OpenTelemetry::SDK::Metrics::State::MetricStore.new }
  let(:meter_provider) { OpenTelemetry::SDK::Metrics::MeterProvider.new }
  let(:instrumentation_scope) { OpenTelemetry::SDK::InstrumentationScope.new('test_scope', '1.0.0') }
  let(:aggregation) { OpenTelemetry::SDK::Metrics::Aggregation::Sum.new }

  describe '#initialize' do
    it 'initializes with empty metric streams' do
      store = OpenTelemetry::SDK::Metrics::State::MetricStore.new
      _(store).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricStore)
    end
  end

  describe '#collect' do
    it 'returns empty array when no metric streams are added' do
      snapshot = metric_store.collect
      _(snapshot).must_be_instance_of(Array)
      _(snapshot).must_be_empty
    end

    it 'collects data from added metric streams' do
      metric_stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      # Add some data to the metric stream
      metric_store.add_metric_stream(metric_stream)
      metric_stream.update(10, {})

      snapshot = metric_store.collect
      _(snapshot).must_be_instance_of(Array)
      _(snapshot.size).must_equal(1)
      _(snapshot.first).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
      _(snapshot.first.name).must_equal('test_counter')
    end

    it 'collects data from multiple metric streams' do
      metric_stream1 = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter1',
        'A test counter 1',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      metric_stream2 = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter2',
        'A test counter 2',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      metric_store.add_metric_stream(metric_stream1)
      metric_store.add_metric_stream(metric_stream2)

      metric_stream1.update(10, {})
      metric_stream2.update(20, {})

      snapshot = metric_store.collect
      _(snapshot.size).must_equal(2)
      names = snapshot.map(&:name)
      _(names).must_include('test_counter1')
      _(names).must_include('test_counter2')
    end

    it 'updates epoch times on each collection' do
      metric_stream = OpenTelemetry::SDK::Metrics::State::MetricStream.new(
        'test_counter',
        'A test counter',
        'count',
        :counter,
        meter_provider,
        instrumentation_scope,
        aggregation
      )

      metric_store.add_metric_stream(metric_stream)

      # First collection
      metric_stream.update(10, {})
      snapshot1 = metric_store.collect
      end_time1 = snapshot1.first.time_unix_nano

      sleep(0.001) # Small delay to ensure different timestamps

      # Second collection
      metric_stream.update(10, {})
      snapshot2 = metric_store.collect
      start_time2 = snapshot2.first.start_time_unix_nano
      end_time2 = snapshot2.first.time_unix_nano

      _(start_time2).must_equal(end_time1)
      _(end_time2).must_be :>, end_time1
    end
  end
end
