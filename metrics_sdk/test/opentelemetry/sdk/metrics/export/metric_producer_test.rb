# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::MetricProducer do
  let(:producer) { OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :cumulative) }

  it 'accepts cumulative aggregation temporality' do
    _(producer.aggregation_temporality).must_equal(:cumulative)
  end

  it 'accepts delta aggregation temporality' do
    producer = OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :delta)

    _(producer.aggregation_temporality).must_equal(:delta)
  end

  it 'requires aggregation temporality' do
    _(proc do
      OpenTelemetry::SDK::Metrics::Export::MetricProducer.new
    end).must_raise(ArgumentError)
  end

  it 'rejects an invalid aggregation temporality' do
    error = _(proc do
      OpenTelemetry::SDK::Metrics::Export::MetricProducer.new(aggregation_temporality: :invalid)
    end).must_raise(ArgumentError)

    _(error.message).must_equal('aggregation_temporality must be :delta or :cumulative')
  end

  it 'requires subclasses to implement #produce' do
    _(proc do
      producer.produce(resource: OpenTelemetry::SDK::Resources::Resource.create)
    end).must_raise(NotImplementedError)
  end

  it 'reports partial metrics, status, and errors in the result' do
    error = StandardError.new('third-party source failed')
    result = OpenTelemetry::SDK::Metrics::Export::MetricProducer::Result.new(
      metrics: ['partial_metric'],
      status: OpenTelemetry::SDK::Metrics::Export::FAILURE,
      errors: [error]
    )

    _(result.metrics).must_equal(['partial_metric'])
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
      def produce(resource:, metric_filter: nil)
        metrics = [
          OpenTelemetry::SDK::Metrics::State::MetricData.new(
            'third_party_counter',
            'a counter from a bridged third-party source',
            'smidgen',
            :counter,
            resource,
            OpenTelemetry::SDK::InstrumentationScope.new('third_party_library', '1.0', nil),
            [
              OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new({ 'source' => 'bridge' }, 0, 0, 42, 0, []),
              OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new({ 'source' => 'ignored' }, 0, 0, 7, 0, [])
            ],
            aggregation_temporality,
            0,
            0,
            true
          )
        ]
        metrics = metric_filter.filter(metrics) if metric_filter
        Result.new(metrics: metrics, status: OpenTelemetry::SDK::Metrics::Export::SUCCESS, errors: [])
      end
    end

    class SourceMetricFilter < OpenTelemetry::SDK::Metrics::Export::MetricFilter
      def test_metric(instrumentation_scope:, name:, kind:, unit:)
        MetricFilterResult::ACCEPT_PARTIAL
      end

      def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
        attributes['source'] == 'bridge' ? MetricFilterResult::ACCEPT : MetricFilterResult::DROP
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

    it 'filters producer data points during collect' do
      OpenTelemetry::SDK.configure

      producer = ThirdPartyMetricProducer.new(aggregation_temporality: :delta)
      reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [producer])
      OpenTelemetry.meter_provider.add_metric_reader(reader)

      collected = reader.collect(metric_filter: SourceMetricFilter.new)
      third_party_metric = collected.find { |metric| metric.name == 'third_party_counter' }

      _(third_party_metric.data_points.length).must_equal(1)
      _(third_party_metric.data_points[0].attributes).must_equal('source' => 'bridge')
      _(third_party_metric.data_points[0].value).must_equal(42)
    end
  end

  describe 'when registered with a MetricReader' do
    class TestMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      attr_reader :resource, :metric_filter

      def initialize(metrics, status: OpenTelemetry::SDK::Metrics::Export::SUCCESS, errors: [])
        super(aggregation_temporality: :cumulative)
        @metrics = metrics
        @status = status
        @errors = errors
      end

      def produce(resource:, metric_filter: nil)
        @resource = resource
        @metric_filter = metric_filter
        Result.new(metrics: @metrics, status: @status, errors: @errors)
      end
    end

    class AcceptAllMetricFilter < OpenTelemetry::SDK::Metrics::Export::MetricFilter
      def test_metric(instrumentation_scope:, name:, kind:, unit:)
        MetricFilterResult::ACCEPT
      end

      def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
        MetricFilterResult::ACCEPT
      end
    end

    def build_reader(producers)
      OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: producers)
    end

    it 'receives the resource and metric filter from the reader' do
      producer = TestMetricProducer.new(['external_metric'])
      reader = build_reader([producer])
      resource = OpenTelemetry::SDK::Resources::Resource.create('service.name' => 'test')
      metric_filter = AcceptAllMetricFilter.new
      reader.register_resource(resource)

      reader.metric_store.stub(:collect, []) do
        metrics = reader.collect(metric_filter:)

        _(metrics).must_equal(['external_metric'])
        _(producer.resource).must_be_same_as(resource)
        _(producer.metric_filter).must_be_same_as(metric_filter)
      end
    end

    it 'merges metrics from multiple producers' do
      reader = build_reader([TestMetricProducer.new(['metric_a']), TestMetricProducer.new(['metric_b'])])

      _(reader.collect).must_equal(%w[metric_a metric_b])
    end

    it 'keeps partial metrics from a failed result' do
      producer = TestMetricProducer.new(['partial_metric'], status: OpenTelemetry::SDK::Metrics::Export::FAILURE)

      _(build_reader([producer]).collect).must_equal(['partial_metric'])
    end

    it 'reports errors from a failed result' do
      error = StandardError.new('boom')
      producer = TestMetricProducer.new(['partial_metric'], status: OpenTelemetry::SDK::Metrics::Export::FAILURE, errors: [error])
      reader = build_reader([producer])
      handled = []

      OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
        _(reader.collect).must_equal(['partial_metric'])
      end

      _(handled.length).must_equal(1)
      _(handled[0][0]).must_be_same_as(error)
      _(handled[0][1]).must_match(/failed to produce metrics/)
    end

    it 'reports a failed result without errors' do
      reader = build_reader([TestMetricProducer.new([], status: OpenTelemetry::SDK::Metrics::Export::TIMEOUT)])
      handled = []

      OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
        reader.collect
      end

      _(handled.length).must_equal(1)
      _(handled[0][0]).must_be_nil
    end

    it 'does not report anything for a successful result' do
      reader = build_reader([TestMetricProducer.new(['metric'])])
      handled = []

      OpenTelemetry.stub(:handle_error, ->(exception: nil, message: nil) { handled << [exception, message] }) do
        reader.collect
      end

      _(handled).must_be_empty
    end
  end
end
