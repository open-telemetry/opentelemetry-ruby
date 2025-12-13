# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir do
  describe 'interface contract' do
    it 'requires subclasses to implement offer and collect' do
      reservoir = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new

      _(-> { reservoir.offer }).must_raise(NotImplementedError)
      _(-> { reservoir.collect }).must_raise(NotImplementedError)
    end
  end

  describe 'complex exemplar reservoir integration test always on filter' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
    let(:exemplar_filter) { OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter }
    let(:exemplar_reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 2) }

    it 'integrate fixed size exemplar reservior with simple counter' do
      reset_metrics_sdk
      meter = create_meter
      histogram = meter.create_histogram('histogram_always_on_exemplar', unit: 'smidgen', description: 'description',
                                                                         exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir)
      histogram.record(1, attributes: { 'foo' => 'bar' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots
      _(last_snapshot[0].description).must_equal 'description'
      _(last_snapshot[0].data_points[0].exemplars[0].value).must_equal 1
    end
  end

  describe 'complex exemplar reservoir integration test always off filter' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
    let(:exemplar_filter) { OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOffExemplarFilter }
    let(:exemplar_reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new(max_size: 2) }

    it 'integrate fixed size exemplar reservior with simple counter' do
      reset_metrics_sdk
      meter = create_meter
      histogram = meter.create_histogram('histogram_always_off_exemplar', unit: 'smidgen', description: 'description',
                                                                          exemplar_filter: exemplar_filter, exemplar_reservoir: exemplar_reservoir)
      histogram.record(1, attributes: { 'foo' => 'bar' })

      metric_exporter.pull
      last_snapshot = metric_exporter.metric_snapshots
      _(last_snapshot[0].description).must_equal 'description'
      _(last_snapshot[0].data_points[0].exemplars.size).must_equal 0
    end
  end
end
