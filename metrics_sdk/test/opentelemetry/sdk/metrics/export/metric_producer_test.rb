# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# Stands in for the pre-aggregated data a bridged third-party source hands to the SDK.
module ThirdPartyMetricData
  module_function

  def build(name, resource:, value: 1)
    OpenTelemetry::SDK::Metrics::State::MetricData.new(
      name,
      'a metric from a bridged third-party source',
      'smidgen',
      :counter,
      resource,
      OpenTelemetry::SDK::InstrumentationScope.new('third_party_library', '1.0', nil),
      [OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new({}, 0, 0, value, 0, [])],
      :cumulative,
      0,
      0,
      true
    )
  end
end

describe OpenTelemetry::SDK::Metrics::Export::MetricProducer do
  let(:producer) { OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :cumulative) }

  def metric_data(name, value: 1)
    ThirdPartyMetricData.build(name, resource: OpenTelemetry::SDK::Resources::Resource.create, value: value)
  end

  it 'accepts cumulative aggregation temporality' do
    _(producer.aggregation_temporality).must_equal(:cumulative)
  end

  it 'accepts delta aggregation temporality' do
    producer = OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :delta)

    _(producer.aggregation_temporality).must_equal(:delta)
  end

  it 'when no aggregation or invalid temporality is given' do
    producer = OpenTelemetry::SDK::Metrics::Export::MetricProducer.new
    _(producer.aggregation_temporality).must_equal(:delta)
  end

  it 'rejects an invalid aggregation temporality' do
    producer = OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :invalid)

    _(producer.aggregation_temporality).must_equal(:delta)
  end

  it 'requires subclasses to implement #produce' do
    _(proc do
      producer.produce(resource: OpenTelemetry::SDK::Resources::Resource.create)
    end).must_raise(NotImplementedError)
  end

  it 'reports partial metrics, status, and errors in the result' do
    error = StandardError.new('third-party source failed')
    partial_metric = metric_data('partial_metric', value: 42)
    result = OpenTelemetry::SDK::Metrics::Export::MetricProducer::Result.new(
      metrics: [partial_metric],
      status: OpenTelemetry::SDK::Metrics::Export::FAILURE,
      errors: [error]
    )

    _(result.metrics).must_equal([partial_metric])
    _(result.metrics[0]).must_be_instance_of(OpenTelemetry::SDK::Metrics::State::MetricData)
    _(result.metrics[0].data_points[0].value).must_equal(42)
    _(result.status).must_equal(OpenTelemetry::SDK::Metrics::Export::FAILURE)
    _(result.errors).must_equal([error])
  end

  it 'requires all result fields' do
    _(proc do
      OpenTelemetry::SDK::Metrics::Export::MetricProducer::Result.new(metrics: [])
    end).must_raise(ArgumentError)
  end

  describe 'with a concrete producer plugged into a reader' do
    before { reset_metrics_sdk }

    class ThirdPartyMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      # It's user's responsibility to implement the produce method that return result with Result class
      def produce(resource:, metric_filter: nil, timeout: nil)
        metrics = [
          OpenTelemetry::SDK::Metrics::State::MetricData.new(
            'third_party_counter',
            'a counter from a bridged third-party source',
            'smidgen',
            :counter,
            resource,
            OpenTelemetry::SDK::InstrumentationScope.new('third_party_library', '1.0', nil),
            [OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new({ 'source' => 'bridge' }, 0, 0, 42, 0, [])],
            aggregation_temporality,
            0,
            0,
            true
          )
        ]
        Result.new(metrics: metrics, status: OpenTelemetry::SDK::Metrics::Export::SUCCESS, errors: [])
      end
    end

    it 'merges the produced metrics with the SDK-collected metrics on collect' do
      OpenTelemetry::SDK.configure

      third_party_producer = ThirdPartyMetricProducer.new(aggregation_temporality: :delta)
      reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [third_party_producer])
      OpenTelemetry.meter_provider.add_metric_reader(reader)

      meter = OpenTelemetry.meter_provider.meter('test')
      counter = meter.create_counter('sdk_counter', unit: 'smidgen', description: 'an sdk-collected counter')
      counter.add(1)

      collected = reader.collect

      sdk_metric = collected.find { |m| m.name == 'sdk_counter' }
      third_party_metric = collected.find { |m| m.name == 'third_party_counter' }

      _(sdk_metric).wont_be_nil
      _(sdk_metric.data_points[0].value).must_equal(1)

      _(third_party_metric).wont_be_nil
      _(third_party_metric.instrumentation_scope.name).must_equal('third_party_library')
      _(third_party_metric.resource).must_be_same_as(OpenTelemetry.meter_provider.resource)
      _(third_party_metric.aggregation_temporality).must_equal(:delta)
      _(third_party_metric.data_points[0].value).must_equal(42)
    end

    it 'receives the resource from the reader' do
      third_party_producer = ThirdPartyMetricProducer.new(aggregation_temporality: :delta)
      reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [third_party_producer])
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test')
      reader.register_resource(resource)

      reader.metric_store.stub(:collect, []) do
        metrics = reader.collect

        _(metrics.map(&:name)).must_equal(['third_party_counter'])
        _(metrics[0].resource).must_be_same_as(resource)
      end
    end

    it 'merges metrics from multiple producers' do
      third_party_producer1 = ThirdPartyMetricProducer.new(aggregation_temporality: :delta)
      third_party_producer2 = ThirdPartyMetricProducer.new(aggregation_temporality: :cumulative)
      reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [third_party_producer1, third_party_producer2])

      reader.metric_store.stub(:collect, []) do
        metrics = reader.collect

        assert_equal 2, metrics.size
        assert_equal %i[delta cumulative], metrics.map(&:aggregation_temporality)

        metrics.each do |metric|
          assert_equal 'third_party_counter', metric.name
          assert_equal 'a counter from a bridged third-party source', metric.description
          assert_equal 'smidgen', metric.unit
          assert_equal :counter, metric.instrument_kind
          assert_equal 0, metric.start_time_unix_nano
          assert_equal 0, metric.time_unix_nano
          assert metric.is_monotonic

          assert_equal 'third_party_library', metric.instrumentation_scope.name
          assert_equal '1.0', metric.instrumentation_scope.version
          assert_nil metric.instrumentation_scope.attributes

          assert_equal 1, metric.data_points.size
          dp = metric.data_points.first
          assert_equal ({ 'source' => 'bridge' }), dp.attributes
          assert_equal 0, dp.start_time_unix_nano
          assert_equal 0, dp.time_unix_nano
          assert_equal 42, dp.value
          assert_equal 0, dp.flags
          assert_empty dp.exemplars
        end
      end
    end
  end

  describe 'failure, timeout, and resource handling' do
    class RaisingMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      def produce(resource:, metric_filter: nil, timeout: nil)
        raise 'bridge exploded'
      end
    end

    class FailingMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      def initialize(status:, errors: [])
        super(aggregation_temporality: :cumulative)
        @status = status
        @errors = errors
      end

      def produce(resource:, metric_filter: nil, timeout: nil)
        Result.new(metrics: [], status: @status, errors: @errors)
      end
    end

    # Records what the reader handed over so the tests can assert on it.
    class RecordingMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      attr_reader :resource, :metric_filter, :timeout, :produced_metrics

      def produce(resource:, metric_filter: nil, timeout: nil)
        @resource = resource
        @metric_filter = metric_filter
        @timeout = timeout
        @produced_metrics = [ThirdPartyMetricData.build('recorded_metric', resource: resource)]
        Result.new(metrics: @produced_metrics, status: OpenTelemetry::SDK::Metrics::Export::SUCCESS, errors: [])
      end
    end

    # Ignores the resource it is given, like a misbehaving bridge.
    class ForeignResourceMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      def produce(resource:, metric_filter: nil, timeout: nil)
        metrics = [ThirdPartyMetricData.build('foreign_metric', resource: OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'other'))]
        Result.new(metrics: metrics, status: OpenTelemetry::SDK::Metrics::Export::SUCCESS, errors: [])
      end
    end

    def build_reader(producers, **options)
      OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: producers, **options)
    end

    it 'keeps collecting when a producer raises' do
      reader = build_reader([RaisingMetricProducer.new, RecordingMetricProducer.new])
      handled = []

      reader.metric_store.stub(:collect, []) do
        OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
          _(reader.collect.map(&:name)).must_equal(['recorded_metric'])
        end
      end

      _(handled.length).must_equal(1)
      _(handled[0][0].message).must_equal('bridge exploded')
    end

    it 'keeps partial metrics and reports a failed result' do
      error = StandardError.new('boom')
      reader = build_reader([FailingMetricProducer.new(status: OpenTelemetry::SDK::Metrics::Export::FAILURE, errors: [error]), RecordingMetricProducer.new])
      handled = []

      reader.metric_store.stub(:collect, []) do
        OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
          _(reader.collect.map(&:name)).must_equal(['recorded_metric'])
        end
      end

      _(handled.length).must_equal(1)
      _(handled[0][0]).must_be_same_as(error)
      _(handled[0][1]).must_match(/failed to produce metrics/)
    end

    it 'reports a failed result that carries no errors' do
      reader = build_reader([FailingMetricProducer.new(status: OpenTelemetry::SDK::Metrics::Export::TIMEOUT)])
      handled = []

      reader.metric_store.stub(:collect, []) do
        OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
          _(reader.collect).must_be_empty
        end
      end

      _(handled.length).must_equal(1)
      _(handled[0][0]).must_be_nil
      _(handled[0][1]).must_match(/failed to produce metrics with status/)
    end

    it 'hands the configured timeout to the producer' do
      producer = RecordingMetricProducer.new
      reader = build_reader([producer], timeout: 5)

      reader.metric_store.stub(:collect, []) { reader.collect }

      _(producer.timeout).must_equal(5)
    end

    it 'hands the reader resource to the producer' do
      producer = RecordingMetricProducer.new
      reader = build_reader([producer])
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test')
      reader.register_resource(resource)

      reader.metric_store.stub(:collect, []) do
        _(reader.collect[0].resource).must_be_same_as(resource)
      end

      _(producer.resource).must_be_same_as(resource)
    end

    it 'replaces a resource the producer stamped itself' do
      producer = ForeignResourceMetricProducer.new
      reader = build_reader([producer])
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test')
      reader.register_resource(resource)

      reader.metric_store.stub(:collect, []) do
        _(reader.collect.map(&:resource).uniq).must_equal([resource])
      end
    end

    it 'leaves metrics that already carry the reader resource untouched' do
      producer = RecordingMetricProducer.new
      reader = build_reader([producer])

      produced = nil
      reader.metric_store.stub(:collect, []) { produced = reader.collect }

      _(produced[0]).must_be_same_as(producer.produced_metrics[0])
    end
  end
end
