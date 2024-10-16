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
