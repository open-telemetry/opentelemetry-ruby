# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::MetricFilter do
  MetricFilter = OpenTelemetry::SDK::Metrics::Export::MetricFilter

  class TestMetricFilter < MetricFilter
    def initialize(metric_results:, accepted_attributes: [])
      @metric_results = metric_results
      @accepted_attributes = accepted_attributes
    end

    def test_metric(instrumentation_scope:, name:, kind:, unit:)
      @metric_results.fetch(name)
    end

    def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
      @accepted_attributes.include?(attributes) ? MetricFilterResult::ACCEPT : MetricFilterResult::DROP
    end
  end

  let(:scope) { OpenTelemetry::SDK::InstrumentationScope.new('test', '1.0', nil) }
  let(:resource) { OpenTelemetry::SDK::Resources::Resource.create }

  def metric(name, attributes)
    data_points = attributes.map do |attrs|
      OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new(attrs, 0, 0, 1, 0, [])
    end
    OpenTelemetry::SDK::Metrics::State::MetricData.new(
      name, '', '1', :counter, resource, scope, data_points, :cumulative, 0, 0, true
    )
  end

  it 'accepts and drops complete metric streams without testing attributes' do
    filter = TestMetricFilter.new(metric_results: { 'accepted' => MetricFilter::MetricFilterResult::ACCEPT, 'dropped' => MetricFilter::MetricFilterResult::DROP })
    metrics = [metric('accepted', [{}]), metric('dropped', [{}])]

    _(filter.filter(metrics).map(&:name)).must_equal(['accepted'])
  end

  it 'filters individual data points for partially accepted streams' do
    accepted = { 'environment' => 'production' }
    dropped = { 'environment' => 'development' }
    filter = TestMetricFilter.new(
      metric_results: { 'requests' => MetricFilter::MetricFilterResult::ACCEPT_PARTIAL },
      accepted_attributes: [accepted]
    )

    filtered = filter.filter([metric('requests', [accepted, dropped])])

    _(filtered.length).must_equal(1)
    _(filtered[0].data_points.map(&:attributes)).must_equal([accepted])
  end

  describe 'point kind' do
    Aggregation = OpenTelemetry::SDK::Metrics::Aggregation

    # Accepts every stream partially and records the kind each test received.
    class KindRecordingMetricFilter < MetricFilter
      attr_reader :metric_kinds, :attribute_kinds

      def initialize
        @metric_kinds = {}
        @attribute_kinds = {}
      end

      def test_metric(instrumentation_scope:, name:, kind:, unit:)
        @metric_kinds[name] = kind
        MetricFilterResult::ACCEPT_PARTIAL
      end

      def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
        @attribute_kinds[name] = kind
        AttributesFilterResult::ACCEPT
      end
    end

    def stream(name, instrument_kind, data_points, is_monotonic: nil)
      OpenTelemetry::SDK::Metrics::State::MetricData.new(
        name, '', '1', instrument_kind, resource, scope, data_points, :cumulative, 0, 0, is_monotonic
      )
    end

    it 'passes the data model point kind rather than the instrument kind' do
      filter = KindRecordingMetricFilter.new
      filter.filter(
        [
          stream('counter', :counter, [Aggregation::NumberDataPoint.new({}, 0, 0, 1, 0, [])], is_monotonic: true),
          stream('up_down_counter', :up_down_counter, [Aggregation::NumberDataPoint.new({}, 0, 0, -1, 0, [])], is_monotonic: false),
          stream('gauge', :gauge, [Aggregation::NumberDataPoint.new({}, 0, 0, 1, 0, [])]),
          stream('histogram', :histogram, [Aggregation::HistogramDataPoint.new({})]),
          stream('exponential_histogram', :histogram, [Aggregation::ExponentialHistogramDataPoint.new({})])
        ]
      )

      expected = {
        'counter' => :sum,
        'up_down_counter' => :sum,
        'gauge' => :gauge,
        'histogram' => :histogram,
        'exponential_histogram' => :exponential_histogram
      }
      _(filter.metric_kinds).must_equal(expected)
      _(filter.attribute_kinds).must_equal(expected)
    end

    it 'passes the point kind produced by a view that changes the aggregation' do
      filter = KindRecordingMetricFilter.new
      filter.filter(
        [
          stream('last_value_counter', :counter, [Aggregation::NumberDataPoint.new({}, 0, 0, 1, 0, [])]),
          stream('sum_histogram', :histogram, [Aggregation::NumberDataPoint.new({}, 0, 0, 1, 0, [])], is_monotonic: true),
          stream('histogram_counter', :counter, [Aggregation::HistogramDataPoint.new({})])
        ]
      )

      _(filter.metric_kinds).must_equal('last_value_counter' => :gauge, 'sum_histogram' => :sum, 'histogram_counter' => :histogram)
    end

    it 'falls back to the default aggregation of the instrument when a stream has no data points' do
      filter = KindRecordingMetricFilter.new
      filter.filter(
        [
          stream('observable_counter', :observable_counter, []),
          stream('observable_gauge', :observable_gauge, []),
          stream('histogram', :histogram, [])
        ]
      )

      _(filter.metric_kinds).must_equal('observable_counter' => :sum, 'observable_gauge' => :gauge, 'histogram' => :histogram)
    end

    describe 'with SDK-collected metrics' do
      before { reset_metrics_sdk }

      it 'passes the point kind of each collected stream' do
        OpenTelemetry::SDK.configure
        OpenTelemetry.meter_provider.add_view('last_value_counter', aggregation: Aggregation::LastValue.new)
        reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new
        OpenTelemetry.meter_provider.add_metric_reader(reader)

        meter = OpenTelemetry.meter_provider.meter('test')
        meter.create_counter('counter').add(1)
        meter.create_counter('last_value_counter').add(1)
        meter.create_gauge('gauge').record(1)
        meter.create_histogram('histogram').record(1)

        filter = KindRecordingMetricFilter.new
        filter.filter(reader.collect)

        _(filter.metric_kinds).must_equal('counter' => :sum, 'last_value_counter' => :gauge, 'gauge' => :gauge, 'histogram' => :histogram)
      end
    end
  end

  describe 'with a MetricProducer' do
    before { reset_metrics_sdk }

    class SourceMetricFilter < OpenTelemetry::SDK::Metrics::Export::MetricFilter
      def test_metric(instrumentation_scope:, name:, kind:, unit:)
        name == 'third_party_counter' ? MetricFilterResult::ACCEPT_PARTIAL : MetricFilterResult::DROP
      end

      def test_attributes(instrumentation_scope:, name:, kind:, unit:, attributes:)
        attributes['source'] == 'bridge' ? MetricFilterResult::ACCEPT : MetricFilterResult::DROP
      end
    end

    class FilteringMetricProducer < OpenTelemetry::SDK::Metrics::Export::MetricProducer
      attr_reader :metric_filter

      def produce(resource:, metric_filter: nil, timeout: nil)
        @metric_filter = metric_filter
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

    let(:producer) { FilteringMetricProducer.new(aggregation_temporality: :delta) }
    let(:reader) { OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [producer]) }

    def build_reader(metric_filter)
      OpenTelemetry::SDK::Metrics::Export::MetricReader.new(metric_producers: [producer], metric_filter: metric_filter)
    end

    it 'is handed to the producer by the reader' do
      metric_filter = SourceMetricFilter.new

      build_reader(metric_filter).collect

      _(producer.metric_filter).must_be_same_as(metric_filter)
    end

    it 'is nil when the reader is configured without one' do
      collected = reader.collect

      _(producer.metric_filter).must_be_nil
      _(collected[0].data_points.length).must_equal(2)
    end

    it 'filters producer data points during collect' do
      OpenTelemetry::SDK.configure

      filtering_reader = build_reader(SourceMetricFilter.new)
      OpenTelemetry.meter_provider.add_metric_reader(filtering_reader)

      collected = filtering_reader.collect
      third_party_metric = collected.find { |metric| metric.name == 'third_party_counter' }

      _(third_party_metric.data_points.length).must_equal(1)
      _(third_party_metric.data_points[0].attributes).must_equal('source' => 'bridge')
      _(third_party_metric.data_points[0].value).must_equal(42)
    end
  end
end
