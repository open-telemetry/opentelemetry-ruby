# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::MeterProvider do
  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
  end

  describe '#meter' do
    it 'requires a meter name' do
      _(-> { OpenTelemetry.meter_provider.meter }).must_raise(ArgumentError)
    end

    it 'creates a new meter' do
      meter = OpenTelemetry.meter_provider.meter('test')

      _(meter).must_be_instance_of(OpenTelemetry::SDK::Metrics::Meter)
    end

    it 'repeated calls does not recreate a meter of the same name' do
      meter_a = OpenTelemetry.meter_provider.meter('test')
      meter_b = OpenTelemetry.meter_provider.meter('test')

      _(meter_a).must_equal(meter_b)
    end
  end

  describe '#shutdown' do
    it 'repeated calls to shutdown result in a failure' do
      with_test_logger do |log_stream|
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::SUCCESS)
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::FAILURE)
        _(log_stream.string).must_match(/calling MetricProvider#shutdown multiple times/)
      end
    end

    it 'returns a no-op meter after being shutdown' do
      with_test_logger do |log_stream|
        OpenTelemetry.meter_provider.shutdown

        _(OpenTelemetry.meter_provider.meter('test')).must_be_instance_of(OpenTelemetry::Metrics::Meter)
        _(log_stream.string).must_match(/calling MeterProvider#meter after shutdown, a noop meter will be returned/)
      end
    end

    it 'returns a timeout response when it times out' do
      mock_metric_reader = new_mock_reader
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.shutdown(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes shutdown on all registered Metric Readers' do
      mock_metric_reader1 = new_mock_reader
      mock_metric_reader2 = new_mock_reader
      mock_metric_reader1.expect(:shutdown, nil, [], timeout: nil)
      mock_metric_reader2.expect(:shutdown, nil, [], timeout: nil)

      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader2)
      OpenTelemetry.meter_provider.shutdown

      mock_metric_reader1.verify
      mock_metric_reader2.verify
    end
  end

  describe '#force_flush' do
    it 'returns a timeout response when it times out' do
      mock_metric_reader = new_mock_reader
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.force_flush(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes force_flush on all registered Metric Readers' do
      mock_metric_reader1 = new_mock_reader
      mock_metric_reader2 = new_mock_reader
      mock_metric_reader1.expect(:force_flush, nil, [], timeout: nil)
      mock_metric_reader2.expect(:force_flush, nil, [], timeout: nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader2)

      OpenTelemetry.meter_provider.force_flush

      mock_metric_reader1.verify
      mock_metric_reader2.verify
    end
  end

  describe '#add_metric_reader' do
    it 'adds a metric reader' do
      metric_reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new

      OpenTelemetry.meter_provider.add_metric_reader(metric_reader)

      _(OpenTelemetry.meter_provider.instance_variable_get(:@metric_readers)).must_equal([metric_reader])
    end

    it 'associates the metric store with instruments created before the metric reader' do
      meter_a = OpenTelemetry.meter_provider.meter('a').create_counter('meter_a')

      metric_reader_a = OpenTelemetry::SDK::Metrics::Export::MetricReader.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_a)

      metric_reader_b = OpenTelemetry::SDK::Metrics::Export::MetricReader.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_b)

      _(meter_a.instance_variable_get(:@metric_streams).size).must_equal(2)
      _(metric_reader_a.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
      _(metric_reader_b.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
    end

    it 'associates the metric store with instruments created after the metric reader' do
      metric_reader_a = OpenTelemetry::SDK::Metrics::Export::MetricReader.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_a)

      metric_reader_b = OpenTelemetry::SDK::Metrics::Export::MetricReader.new
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_b)

      meter_a = OpenTelemetry.meter_provider.meter('a').create_counter('meter_a')

      _(meter_a.instance_variable_get(:@metric_streams).size).must_equal(2)
      _(metric_reader_a.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
      _(metric_reader_b.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
    end
  end

  describe '#add_view' do
    it 'adds a view with aggregation' do
      OpenTelemetry.meter_provider.add_view('test', aggregation: ::OpenTelemetry::SDK::Metrics::Aggregation::Drop.new)

      registered_views = OpenTelemetry.meter_provider.instance_variable_get(:@registered_views)

      _(registered_views.size).must_equal 1
      _(registered_views[0].class).must_equal ::OpenTelemetry::SDK::Metrics::View::RegisteredView
      _(registered_views[0].name).must_equal 'test'
      _(registered_views[0].aggregation.class).must_equal ::OpenTelemetry::SDK::Metrics::Aggregation::Drop
    end

    it 'add a view without aggregation but aggregation as nil' do
      OpenTelemetry.meter_provider.add_view('test')

      registered_views = OpenTelemetry.meter_provider.instance_variable_get(:@registered_views)

      _(registered_views.size).must_equal 1
      _(registered_views[0].aggregation).must_be_nil
    end
  end

  private

  def new_mock_reader
    Minitest::Mock.new(OpenTelemetry::SDK::Metrics::Export::MetricReader.new)
  end
end
