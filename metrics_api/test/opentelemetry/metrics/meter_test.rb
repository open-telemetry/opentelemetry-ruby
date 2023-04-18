# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::Meter do
  let(:instrument_name_error)        { OpenTelemetry::Metrics::Meter::InstrumentNameError }
  let(:instrument_unit_error)        { OpenTelemetry::Metrics::Meter::InstrumentUnitError }
  let(:instrument_description_error) { OpenTelemetry::Metrics::Meter::InstrumentDescriptionError }
  let(:duplicate_instrument_error)   { OpenTelemetry::Metrics::Meter::DuplicateInstrumentError }

  let(:meter_provider) { OpenTelemetry::Metrics::MeterProvider.new }
  let(:meter) { meter_provider.meter('test-meter') }

  describe '#create_counter' do
    it 'duplicate instrument registration logs a warning' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter')
        meter.create_counter('a_counter')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument a_counter/)
      end
    end

    it 'instrument name must not be nil' do
      _(-> { meter.create_counter(nil) }).must_raise(instrument_name_error)
    end

    it 'instument name must not be an empty string' do
      _(-> { meter.create_counter('') }).must_raise(instrument_name_error)
    end

    it 'instrument name must have an alphabetic first character' do
      _(meter.create_counter('one_counter'))
      _(-> { meter.create_counter('1_counter') }).must_raise(instrument_name_error)
    end

    it 'instrument name must not exceed 63 character limit' do
      long_name = 'a' * 63
      meter.create_counter(long_name)
      _(-> { meter.create_counter(long_name + 'a') }).must_raise(instrument_name_error)
    end

    it 'instrument name must belong to alphanumeric characters, _, ., and -' do
      meter.create_counter('a_-..-_a')
      _(-> { meter.create_counter('a@') }).must_raise(instrument_name_error)
      _(-> { meter.create_counter('a!') }).must_raise(instrument_name_error)
    end

    it 'instrument unit must be ASCII' do
      _(-> { meter.create_counter('a_counter', unit: 'á') }).must_raise(instrument_unit_error)
    end

    it 'instrument unit must not exceed 63 characters' do
      long_unit = 'a' * 63
      meter.create_counter('a_counter', unit: long_unit)
      _(-> { meter.create_counter('b_counter', unit: long_unit + 'a') }).must_raise(instrument_unit_error)
    end

    it 'instrument description must be utf8mb3' do
      _(-> { meter.create_counter('a_counter', description: '💩'.dup) }).must_raise(instrument_description_error)
      _(-> { meter.create_counter('b_counter', description: "\xc2".dup) }).must_raise(instrument_description_error)
    end

    it 'instrument description must not exceed 1023 characters' do
      long_description = 'a' * 1023
      meter.create_counter('a_counter', description: long_description)
      _(-> { meter.create_counter('b_counter', description: long_description + 'a') }).must_raise(instrument_description_error)
    end
  end

  describe '#create_histogram' do
    it 'raises an error when name does not match pattern' do
      invalid_names.each do |invalid_name|
        _(-> { meter.create_histogram(invalid_name) })
          .must_raise(instrument_name_error, "should have raised for name=#{invalid_name.inspect}")
      end
    end

    it 'raises an error when unit is invalid' do
      invalid_units.each do |invalid_unit|
        _(-> { meter.create_histogram('an_instrument', unit: invalid_unit) })
          .must_raise(instrument_unit_error, "should have raised for unit=#{invalid_unit.inspect}")
      end
    end

    it 'raises an error when description is invalid' do
      invalid_descriptions.each do |invalid_description|
        _(-> { meter.create_histogram('an_instrument', description: invalid_description) })
          .must_raise(instrument_description_error, "should have raised for description=#{invalid_description.inspect}")
      end
    end

    it 'creates and returns an instance of Histogram instrument' do
      assert(meter.create_histogram('an_instrument')
        .is_a?(OpenTelemetry::Metrics::Instrument::Histogram))
    end

    it 'logs a warning message when instrument with same name already exists' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_histogram('an_instrument')
        meter.create_histogram('AN_INSTRUMENT')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument an_instrument/)
      end
    end
  end

  describe '#create_up_down_counter' do
    it 'raises an error when name does not match pattern' do
      invalid_names.each do |invalid_name|
        _(-> { meter.create_up_down_counter(invalid_name) })
          .must_raise(instrument_name_error, "should have raised for name=#{invalid_name.inspect}")
      end
    end

    it 'raises an error when unit is invalid' do
      invalid_units.each do |invalid_unit|
        _(-> { meter.create_up_down_counter('an_instrument', unit: invalid_unit) })
          .must_raise(instrument_unit_error, "should have raised for unit=#{invalid_unit.inspect}")
      end
    end

    it 'raises an error when description is invalid' do
      invalid_descriptions.each do |invalid_description|
        _(-> { meter.create_up_down_counter('an_instrument', description: invalid_description) })
          .must_raise(instrument_description_error, "should have raised for description=#{invalid_description.inspect}")
      end
    end

    it 'creates and returns an instance of UpDownCounter instrument' do
      assert(meter.create_up_down_counter('an_instrument')
        .is_a?(OpenTelemetry::Metrics::Instrument::UpDownCounter))
    end

    it 'logs a warning message when instrument with same name already exists' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_up_down_counter('an_instrument')
        meter.create_up_down_counter('AN_INSTRUMENT')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument an_instrument/)
      end
    end
  end

  describe '#create_observable_counter' do
    it 'raises an error when name does not match pattern' do
      invalid_names.each do |invalid_name|
        _(-> { meter.create_observable_counter(invalid_name, callback: -> {}) })
          .must_raise(instrument_name_error, "should have raised for name=#{invalid_name.inspect}")
      end
    end

    it 'raises an error when unit is invalid' do
      invalid_units.each do |invalid_unit|
        _(-> { meter.create_observable_counter('an_instrument', unit: invalid_unit, callback: -> {}) })
          .must_raise(instrument_unit_error, "should have raised for unit=#{invalid_unit.inspect}")
      end
    end

    it 'raises an error when description is invalid' do
      invalid_descriptions.each do |invalid_description|
        _(-> { meter.create_observable_counter('an_instrument', description: invalid_description, callback: -> {}) })
          .must_raise(instrument_description_error, "should have raised for description=#{invalid_description.inspect}")
      end
    end

    it 'creates and returns an instance of ObservableCounter instrument' do
      assert(meter.create_observable_counter('an_instrument', callback: -> {})
        .is_a?(OpenTelemetry::Metrics::Instrument::ObservableCounter))
    end

    it 'logs a warning message when instrument with same name already exists' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_counter('an_instrument', callback: -> {})
        meter.create_observable_counter('AN_INSTRUMENT', callback: -> {})
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument an_instrument/)
      end
    end
  end

  describe '#create_observable_gauge' do
    it 'raises an error when name does not match pattern' do
      invalid_names.each do |invalid_name|
        _(-> { meter.create_observable_gauge(invalid_name, callback: -> {}) })
          .must_raise(instrument_name_error, "should have raised for name=#{invalid_name.inspect}")
      end
    end

    it 'raises an error when unit is invalid' do
      invalid_units.each do |invalid_unit|
        _(-> { meter.create_observable_gauge('an_instrument', unit: invalid_unit, callback: -> {}) })
          .must_raise(instrument_unit_error, "should have raised for unit=#{invalid_unit.inspect}")
      end
    end

    it 'raises an error when description is invalid' do
      invalid_descriptions.each do |invalid_description|
        _(-> { meter.create_observable_gauge('an_instrument', description: invalid_description, callback: -> {}) })
          .must_raise(instrument_description_error, "should have raised for description=#{invalid_description.inspect}")
      end
    end

    it 'creates and returns an instance of ObservableGauge instrument' do
      assert(meter.create_observable_gauge('an_instrument', callback: -> {})
        .is_a?(OpenTelemetry::Metrics::Instrument::ObservableGauge))
    end

    it 'logs a warning message when instrument with same name already exists' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_gauge('an_instrument', callback: -> {})
        meter.create_observable_gauge('AN_INSTRUMENT', callback: -> {})
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument an_instrument/)
      end
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'raises an error when name does not match pattern' do
      invalid_names.each do |invalid_name|
        _(-> { meter.create_observable_up_down_counter(invalid_name, callback: -> {}) })
          .must_raise(instrument_name_error, "should have raised for name=#{invalid_name.inspect}")
      end
    end

    it 'raises an error when unit is invalid' do
      invalid_units.each do |invalid_unit|
        _(-> { meter.create_observable_up_down_counter('an_instrument', unit: invalid_unit, callback: -> {}) })
          .must_raise(instrument_unit_error, "should have raised for unit=#{invalid_unit.inspect}")
      end
    end

    it 'raises an error when description is invalid' do
      invalid_descriptions.each do |invalid_description|
        _(-> { meter.create_observable_up_down_counter('an_instrument', description: invalid_description, callback: -> {}) })
          .must_raise(instrument_description_error, "should have raised for description=#{invalid_description.inspect}")
      end
    end

    it 'creates and returns an instance of ObservableUpDownCounter instrument' do
      assert(meter.create_observable_up_down_counter('an_instrument', callback: -> {})
        .is_a?(OpenTelemetry::Metrics::Instrument::ObservableUpDownCounter))
    end

    it 'logs a warning message when instrument with same name already exists' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_observable_up_down_counter('an_instrument', callback: -> {})
        meter.create_observable_up_down_counter('AN_INSTRUMENT', callback: -> {})
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument an_instrument/)
      end
    end
  end

  let(:invalid_names) do
    [
      nil,
      '',
      ' ',
      '1_meter',
      '_meter',
      '-meter',
      '.meter',
      'a' * 64,
      'a@',
      'a!'
    ]
  end

  let(:invalid_units) do
    [
      'á',
      'a' * 64
    ]
  end

  let(:invalid_descriptions) do
    [
      'a' * 1024,
      '💩',
      "\xc2"
    ]
  end
end
