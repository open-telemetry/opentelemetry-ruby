# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Export::MetricReader do
  let(:sum) { OpenTelemetry::SDK::Metrics::Aggregation::Sum }
  let(:last_value) { OpenTelemetry::SDK::Metrics::Aggregation::LastValue }
  let(:explicit_bucket_histogram) { OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram }
  let(:exponential_bucket_histogram) { OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram }

  describe '#default_aggregation' do
    it 'defaults to the aggregation defined by the specification' do
      default_aggregation = OpenTelemetry::SDK::Metrics::Export::MetricReader.new.default_aggregation

      _(default_aggregation[:counter]).must_equal(sum)
      _(default_aggregation[:up_down_counter]).must_equal(sum)
      _(default_aggregation[:observable_counter]).must_equal(sum)
      _(default_aggregation[:observable_up_down_counter]).must_equal(sum)
      _(default_aggregation[:gauge]).must_equal(last_value)
      _(default_aggregation[:observable_gauge]).must_equal(last_value)
      _(default_aggregation[:histogram]).must_equal(explicit_bucket_histogram)
    end

    it 'applies the provided aggregation on top of the defaults' do
      reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(default_aggregation: { histogram: exponential_bucket_histogram })

      _(reader.default_aggregation[:histogram]).must_equal(exponential_bucket_histogram)
      _(reader.default_aggregation[:counter]).must_equal(sum)
    end

    it 'does not modify the shared defaults' do
      OpenTelemetry::SDK::Metrics::Export::MetricReader.new(default_aggregation: { histogram: exponential_bucket_histogram })

      _(OpenTelemetry::SDK::Metrics::Export::MetricReader::DEFAULT_AGGREGATION[:histogram]).must_equal(explicit_bucket_histogram)
    end

    it 'is available to pull exporters' do
      reader = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(default_aggregation: { histogram: exponential_bucket_histogram })

      _(reader.default_aggregation[:histogram]).must_equal(exponential_bucket_histogram)
    end
  end

  describe 'aggregation selection' do
    before { reset_metrics_sdk }

    it 'uses the reader preference for instruments created afterwards' do
      reader = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(default_aggregation: { histogram: exponential_bucket_histogram })
      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(reader)

      OpenTelemetry.meter_provider.meter('test').create_histogram('histogram').record(5)
      reader.pull

      snapshot = reader.metric_snapshots.find { |s| s.name == 'histogram' }
      _(snapshot.data_points[0]).must_be_instance_of(OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogramDataPoint)
    end

    it 'uses the reader preference for instruments created beforehand' do
      OpenTelemetry::SDK.configure
      histogram = OpenTelemetry.meter_provider.meter('test').create_histogram('histogram')

      reader = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new(default_aggregation: { histogram: exponential_bucket_histogram })
      OpenTelemetry.meter_provider.add_metric_reader(reader)

      histogram.record(5)
      reader.pull

      snapshot = reader.metric_snapshots.find { |s| s.name == 'histogram' }
      _(snapshot.data_points[0]).must_be_instance_of(OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogramDataPoint)
    end

    it 'falls back to the specification defaults for a reader without a preference' do
      reader = Class.new(OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter) do
        undef_method :default_aggregation
      end.new
      OpenTelemetry::SDK.configure
      OpenTelemetry.meter_provider.add_metric_reader(reader)

      OpenTelemetry.meter_provider.meter('test').create_histogram('histogram').record(5)
      reader.pull

      snapshot = reader.metric_snapshots.find { |s| s.name == 'histogram' }
      _(snapshot.data_points[0]).must_be_instance_of(OpenTelemetry::SDK::Metrics::Aggregation::HistogramDataPoint)
    end
  end
end
