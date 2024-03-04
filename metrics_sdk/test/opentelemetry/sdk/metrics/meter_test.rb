# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Meter do
  before { OpenTelemetry::SDK.configure }

  let(:meter) { OpenTelemetry.meter_provider.meter('new_meter') }

  describe '#create_counter' do
    it 'creates a counter instrument' do
      instrument = meter.create_counter('a_counter', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Counter
    end
  end

  describe '#create_histogram' do
    it 'creates a histogram instrument' do
      instrument = meter.create_histogram('a_histogram', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Histogram
    end
  end

  describe '#create_up_down_counter' do
    it 'creates a up_down_counter instrument' do
      instrument = meter.create_up_down_counter('a_up_down_counter', unit: 'minutes', description: 'useful description')
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::UpDownCounter
    end
  end

  describe '#create_observable_counter' do
    it 'creates a observable_counter instrument' do
      instrument = meter.create_observable_counter('a_observable_counter', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter
    end
  end

  describe '#create_observable_gauge' do
    it 'creates a observable_gauge instrument' do
      instrument = meter.create_observable_gauge('a_observable_gauge', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'creates a observable_up_down_counter instrument' do
      instrument = meter.create_observable_up_down_counter('a_observable_up_down_counter', unit: 'minutes', description: 'useful description', callback: proc { 10 })
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter
    end
  end

  describe 'callback' do
    describe '#register_callback' do
      let(:metric_exporter) { OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new }
      let(:meter) { OpenTelemetry.meter_provider.meter('test') }

      before do
        reset_metrics_sdk
        OpenTelemetry::SDK.configure
        OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
      end

      it 'create callback with multi asychronous instrument' do
        callback_first = proc { 10 }
        counter_first  = meter.create_observable_counter('counter_first', unit: 'smidgen', description: '', callback: callback_first)
        counter_second = meter.create_observable_counter('counter_second', unit: 'smidgen', description: '', callback: callback_first)

        callback_second = proc { 20 }
        meter.register_callback([counter_first, counter_second], callback_second)

        _(counter_first.instance_variable_get(:@callbacks).size).must_equal 2
        _(counter_second.instance_variable_get(:@callbacks).size).must_equal 2

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots.last

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(30)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(30)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)
      end

      it 'remove callback with multi asychronous instrument' do
        callback_first = proc { 10 }
        counter_first  = meter.create_observable_counter('counter_first', unit: 'smidgen', description: '', callback: callback_first)
        counter_second = meter.create_observable_counter('counter_second', unit: 'smidgen', description: '', callback: callback_first)

        callback_second = proc { 20 }
        meter.register_callback([counter_first, counter_second], callback_second)

        _(counter_first.instance_variable_get(:@callbacks).size).must_equal 2
        _(counter_second.instance_variable_get(:@callbacks).size).must_equal 2

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots.last

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(30)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(30)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)

        # unregister the callback_second from instruments counter_first and counter_second
        meter.unregister([counter_first, counter_second], callback_second)

        metric_exporter.pull
        last_snapshot = metric_exporter.metric_snapshots.last

        _(last_snapshot[0].name).must_equal('counter_first')
        _(last_snapshot[0].unit).must_equal('smidgen')
        _(last_snapshot[0].description).must_equal('')
        _(last_snapshot[0].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[0].data_points[0].value).must_equal(10)
        _(last_snapshot[0].data_points[0].attributes).must_equal({})
        _(last_snapshot[0].aggregation_temporality).must_equal(:delta)

        _(last_snapshot[1].name).must_equal('counter_second')
        _(last_snapshot[1].unit).must_equal('smidgen')
        _(last_snapshot[1].description).must_equal('')
        _(last_snapshot[1].instrumentation_scope.name).must_equal('test')
        _(last_snapshot[1].data_points[0].value).must_equal(10)
        _(last_snapshot[1].data_points[0].attributes).must_equal({})
        _(last_snapshot[1].aggregation_temporality).must_equal(:delta)
      end
    end
  end
end
