# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Meter do
  describe '#name' do
    it 'returns name' do
      meter = build_meter('test-meter')

      assert(meter.name == 'test-meter')
    end
  end

  describe '#version' do
    it 'returns version' do
      meter = build_meter('test-meter')
      assert(meter.version == '')

      meter = build_meter('test-meter', version: '1.0.0')
      assert(meter.version == '1.0.0')
    end
  end

  describe '#schema_url' do
    it 'returns schema_url' do
      meter = build_meter('test-meter')
      assert(meter.schema_url == '')

      meter = build_meter('test-meter', schema_url: 'https://example.com/schema/1.0.0')
      assert(meter.schema_url == 'https://example.com/schema/1.0.0')
    end
  end

  describe '#attributes' do
    it 'returns attributes' do
      meter = build_meter('test-meter')
      assert(meter.attributes == {})

      meter = build_meter('test-meter', attributes: { 'key' => 'value' })
      assert(meter.attributes == { 'key' => 'value' })
    end
  end

  describe '#create_counter' do
    it 'creates and returns an instance of Counter instrument' do
      meter = build_meter

      instrument = meter.create_counter(
        'test-instrument',
        unit: 'b',
        description: 'number of bytes received',
        advice: {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::Counter))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('test-instrument')
        meter.create_counter('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  describe '#create_histogram' do
    it 'creates and returns an instance of Histogram instrument' do
      meter = build_meter

      instrument = meter.create_histogram(
        'test-instrument',
        unit: 'ms',
        description: 'request duration',
        advice: {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::Histogram))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_histogram('test-instrument')
        meter.create_histogram('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  describe '#create_up_down_counter' do
    it 'creates and returns an instance of UpDownCounter instrument' do
      meter = build_meter

      instrument = meter.create_up_down_counter(
        'test-instrument',
        unit: 'items',
        description: 'number of items in a queue',
        advice: {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::UpDownCounter))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_up_down_counter('test-instrument')
        meter.create_up_down_counter('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  describe '#create_observable_counter' do
    it 'creates and returns an instance of ObservableCounter instrument' do
      meter = build_meter

      instrument = meter.create_observable_counter(
        'test-instrument',
        unit: 'fault',
        description: 'number of page faults',
        callbacks: -> {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::ObservableCounter))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_counter('test-instrument')
        meter.create_observable_counter('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  describe '#create_observable_gauge' do
    it 'creates and returns an instance of ObservableGauge instrument' do
      meter = build_meter

      instrument = meter.create_observable_gauge(
        'test-instrument',
        unit: 'celsius',
        description: 'room temperature',
        callbacks: -> {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::ObservableGauge))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_gauge('test-instrument')
        meter.create_observable_gauge('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'creates and returns an instance of ObservableUpDownCounter instrument' do
      meter = build_meter

      instrument = meter.create_observable_up_down_counter(
        'test-instrument',
        unit: 'b',
        description: 'process heap size',
        callbacks: -> {}
      )

      assert(instrument.is_a?(OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter))
    end

    it 'logs a warning message when an instrument with the same name already exists' do
      meter = build_meter

      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_up_down_counter('test-instrument')
        meter.create_observable_up_down_counter('TEST-INSTRUMENT')

        assert(log_stream.string.match?(/duplicate instrument registration occurred for test-instrument/))
      end
    end
  end

  def build_meter(name = 'test-meter', **kwargs)
    OpenTelemetry::Metrics::Meter.new(name, **kwargs)
  end
end
