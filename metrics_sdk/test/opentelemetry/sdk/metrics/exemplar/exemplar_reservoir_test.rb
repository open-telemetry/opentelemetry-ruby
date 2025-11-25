# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir do
  describe 'basic exemplar reservoir operation test' do
    let(:context) do
      ::OpenTelemetry::Trace.context_with_span(
        ::OpenTelemetry::Trace.non_recording_span(
          ::OpenTelemetry::Trace::SpanContext.new(
            trace_id: Array("w\xCBl\xCCR-1\x06\x11M\xD6\xEC\xBBp\x03j").pack('H*'),
            span_id: Array("1\xE1u\x12\x8E\xFC@\x18").pack('H*'),
            trace_flags: ::OpenTelemetry::Trace::TraceFlags::DEFAULT
          )
        )
      )
    end
    let(:timestamp) { 123_456_789 }
    let(:attributes) { { 'test': 'test' } }

    it 'basic test for exemplar reservoir' do
      exemplar = OpenTelemetry::SDK::Metrics::Exemplar::ExemplarReservoir.new
      exemplar.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = exemplar.collect

      _(exemplars.class).must_equal Array
      _(exemplars[0].class).must_equal OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
      _(exemplars[0].value).must_equal 1
      _(exemplars[0].time_unix_nano).must_equal 123_456_789
      _(exemplars[0].attributes[:test]).must_equal 'test'
      _(exemplars[0].span_id).must_equal '11e2ec08'
      _(exemplars[0].trace_id).must_equal '0b5cbd16166cb933'
    end

    it 'basic test for fixed size exemplar reservoir' do
      exemplar = OpenTelemetry::SDK::Metrics::Exemplar::FixedSizeExemplarReservoir.new(max_size: 2)
      exemplar.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = exemplar.collect

      _(exemplars.class).must_equal Array
      _(exemplars[0].class).must_equal OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
      _(exemplars[0].value).must_equal 1
      _(exemplars[0].time_unix_nano).must_equal 123_456_789
      _(exemplars[0].attributes[:test]).must_equal 'test'
      _(exemplars[0].span_id).must_equal '11e2ec08'
      _(exemplars[0].trace_id).must_equal '0b5cbd16166cb933'
    end

    it 'basic test for fixed size exemplar reservoir when more offers' do
      exemplar = OpenTelemetry::SDK::Metrics::Exemplar::FixedSizeExemplarReservoir.new(max_size: 2)
      exemplar.offer(value: 1, timestamp: timestamp, attributes: attributes, context: context)
      exemplar.offer(value: 2, timestamp: timestamp, attributes: attributes, context: context)
      exemplar.offer(value: 3, timestamp: timestamp, attributes: attributes, context: context)

      exemplars = exemplar.collect
      _(exemplars.class).must_equal Array
      _(exemplars[0].class).must_equal OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
      _(exemplars.size).must_equal 2
    end

    it 'basic test for histogram exemplar reservoir' do
      exemplar = OpenTelemetry::SDK::Metrics::Exemplar::HistogramExemplarReservoir.new
      exemplar.offer(value: 20, timestamp: timestamp, attributes: attributes, context: context)
      exemplars = exemplar.collect

      _(exemplars.class).must_equal Array
      _(exemplars[0].class).must_equal OpenTelemetry::SDK::Metrics::Exemplar::Exemplar
      _(exemplars[0].value).must_equal 20
      _(exemplars[0].time_unix_nano).must_equal 123_456_789
      _(exemplars[0].attributes[:test]).must_equal 'test'
      _(exemplars[0].span_id).must_equal '11e2ec08'
      _(exemplars[0].trace_id).must_equal '0b5cbd16166cb933'
    end
  end

  describe 'complex exemplar reservoir integration test always on filter' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
    let(:exemplar_filter) { OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOnExemplarFilter }
    let(:exemplar_reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::FixedSizeExemplarReservoir.new(max_size: 2) }

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
      _(last_snapshot[0].data_points[0].exemplars[0].attributes['foo']).must_equal 'bar'
      _(last_snapshot[0].data_points[0].exemplars[0].span_id).must_equal '0000000000000000'
      _(last_snapshot[0].data_points[0].exemplars[0].trace_id).must_equal '00000000000000000000000000000000'
    end
  end

  describe 'complex exemplar reservoir integration test always off filter' do
    let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
    let(:exemplar_filter) { OpenTelemetry::SDK::Metrics::Exemplar::AlwaysOffExemplarFilter }
    let(:exemplar_reservoir) { OpenTelemetry::SDK::Metrics::Exemplar::FixedSizeExemplarReservoir.new(max_size: 2) }

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
