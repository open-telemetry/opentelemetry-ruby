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
end
