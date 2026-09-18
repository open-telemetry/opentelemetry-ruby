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

    it 'case-insensitive duplicate instrument registration logs a warning' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('requestCount')
        meter.create_counter('RequestCount')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument RequestCount/)
      end
    end

    it 'test create_counter' do
      counter = meter.create_counter('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::Counter)
    end

    it 'reuses matching proxy instruments before and after installing a delegate' do
      proxy = OpenTelemetry::Internal::ProxyMeter.new
      first = proxy.create_counter('requestCount')
      _(proxy.create_counter('RequestCount')).must_be_same_as(first)

      proxy.delegate = meter

      _(proxy.create_counter('REQUESTCOUNT')).must_be_same_as(first)
      first.add(1)
    end

    it 'reuses observable proxy instruments with the same identity' do
      proxy = OpenTelemetry::Internal::ProxyMeter.new
      first = proxy.create_observable_counter('requestCount', callback: -> { 1 })
      second = proxy.create_observable_counter('RequestCount', callback: -> { 2 })

      _(second).must_be_same_as(first)
      _(proxy.create_observable_counter('REQUESTCOUNT', callback: -> { 3 })).must_be_same_as(first)
    end

    it 'preserves first-seen names for distinct proxy instruments across delegation' do
      names = []
      delegate = OpenTelemetry::Metrics::Meter.new
      delegate.define_singleton_method(:create_counter) do |name, **options|
        names << name
        super(name, **options)
      end
      proxy = OpenTelemetry::Internal::ProxyMeter.new
      first = proxy.create_counter('requestCount', unit: 's')
      second = proxy.create_counter('RequestCount', unit: 'ms')

      _(second).wont_be_same_as(first)
      proxy.delegate = delegate
      _(names).must_equal(%w[requestCount requestCount])
      _(proxy.create_counter('REQUESTCOUNT', unit: 'ms')).must_be_same_as(second)

      proxy.create_counter('REQUESTCOUNT', unit: 's', description: 'new description')
      _(names).must_equal(%w[requestCount requestCount requestCount])
      first.add(1)
      second.add(1)
    end

    it 'test create_histogram' do
      counter = meter.create_histogram('test')
      _(counter.class).must_equal(OpenTelemetry::Metrics::Instrument::Histogram)
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
end
