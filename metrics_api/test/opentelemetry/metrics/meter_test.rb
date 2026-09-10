# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Meter do
  let(:meter_provider) { OpenTelemetry::Metrics::MeterProvider.new }
  let(:meter) { meter_provider.meter('test-meter') }

  describe 'creating an instrument' do
    it 'duplicate instrument registration logs a warning' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter')
        meter.create_counter('a_counter')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument a_counter/)
      end
    end

    it 'test create_counter' do
      counter = meter.create_counter('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::Counter)
    end

    it 'test create_histogram' do
      counter = meter.create_histogram('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::Histogram)
    end

    it 'test create_gauge' do
      gauge = meter.create_gauge('test')
      _(gauge.class).must_equal(OpenTelemetry::Metrics::Instrument::Gauge)
    end

    it 'test create_up_down_counter' do
      counter = meter.create_up_down_counter('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::UpDownCounter)
    end

    it 'test create_observable_counter' do
      counter = meter.create_observable_counter('test', callback: -> {})
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableCounter)
    end

    it 'test create_observable_gauge' do
      counter = meter.create_observable_gauge('test', callback: -> {})
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableGauge)
    end

    it 'test create_observable_up_down_counter' do
      counter = meter.create_observable_up_down_counter('test', callback: -> {})
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter)
    end
  end

  describe 'creating an asynchronous instrument without a callback' do
    it 'creates an observable_counter with zero callbacks' do
      counter = meter.create_observable_counter('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableCounter)
    end

    it 'creates an observable_gauge with zero callbacks' do
      gauge = meter.create_observable_gauge('test')
      _(gauge.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableGauge)
    end

    it 'creates an observable_up_down_counter with zero callbacks' do
      counter = meter.create_observable_up_down_counter('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter)
    end
  end

  describe 'advisory parameters' do
    let(:advisory) { { explicit_bucket_boundaries: [0, 5, 10], attributes: ['http.request.method'] } }

    it 'accepts advisory parameters on every synchronous instrument' do
      _(meter.create_counter('c', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::Counter)
      _(meter.create_histogram('h', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::Histogram)
      _(meter.create_gauge('g', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::Gauge)
      _(meter.create_up_down_counter('udc', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::UpDownCounter)
    end

    it 'accepts advisory parameters on every asynchronous instrument' do
      _(meter.create_observable_counter('oc', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableCounter)
      _(meter.create_observable_gauge('og', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableGauge)
      _(meter.create_observable_up_down_counter('oudc', advisory: advisory).class).must_equal(OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter)
    end

    it 'does not validate advisory parameters' do
      counter = meter.create_counter('c', advisory: { not_a_real_advisory_key: Object.new })
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::Counter)
    end
  end

  describe 'multiple-instrument callbacks' do
    let(:callback) { -> {} }
    let(:instruments) { [meter.create_observable_counter('oc'), meter.create_observable_gauge('og')] }

    it 'registers a callback against a set of instruments without raising' do
      _(meter.register_callback(instruments, callback)).must_equal(instruments)
    end

    it 'unregisters a callback from a set of instruments without raising' do
      meter.register_callback(instruments, callback)
      _(meter.unregister(instruments, callback)).must_equal(instruments)
    end
  end
end
