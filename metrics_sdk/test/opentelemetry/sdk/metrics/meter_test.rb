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
      # TODO: Implement observable instruments
      skip
      instrument = meter.create_observable_counter('a_observable_counter', unit: 'minutes', description: 'useful description', callback: nil)
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter
    end
  end

  describe '#create_observable_gauge' do
    it 'creates a observable_gauge instrument' do
      # TODO: Implement observable instruments
      skip
      instrument = meter.create_observable_gauge('a_observable_gauge', unit: 'minutes', description: 'useful description', callback: nil)
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'creates a observable_up_down_counter instrument' do
      # TODO: Implement observable instruments
      skip
      instrument = meter.create_observable_up_down_counter('a_observable_up_down_counter', unit: 'minutes', description: 'useful description', callback: nil)
      _(instrument).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter
    end
  end

  describe 'creating an instrument' do
    INSTRUMENT_NAME_ERROR = OpenTelemetry::Metrics::Meter::InstrumentNameError
    INSTRUMENT_UNIT_ERROR = OpenTelemetry::Metrics::Meter::InstrumentUnitError
    INSTRUMENT_DESCRIPTION_ERROR = OpenTelemetry::Metrics::Meter::InstrumentDescriptionError
    DUPLICATE_INSTRUMENT_ERROR = OpenTelemetry::Metrics::Meter::DuplicateInstrumentError

    it 'duplicate instrument registration logs a warning' do
      OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
        meter.create_counter('a_counter')
        meter.create_counter('a_counter')
        _(log_stream.string).must_match(/duplicate instrument registration occurred for instrument a_counter/)
      end
    end

    it 'instrument name must not be nil' do
      _(-> { meter.create_counter(nil) }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instument name must not be an empty string' do
      _(-> { meter.create_counter('') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must have an alphabetic first character' do
      _(meter.create_counter('one_counter'))
      _(-> { meter.create_counter('1_counter') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must not exceed 63 character limit' do
      long_name = 'a' * 63
      meter.create_counter(long_name)
      _(-> { meter.create_counter(long_name + 'a') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument name must belong to alphanumeric characters, _, ., and -' do
      meter.create_counter('a_-..-_a')
      _(-> { meter.create_counter('a@') }).must_raise(INSTRUMENT_NAME_ERROR)
      _(-> { meter.create_counter('a!') }).must_raise(INSTRUMENT_NAME_ERROR)
    end

    it 'instrument unit must be ASCII' do
      _(-> { meter.create_counter('a_counter', unit: 'á') }).must_raise(INSTRUMENT_UNIT_ERROR)
    end

    it 'instrument unit must not exceed 63 characters' do
      long_unit = 'a' * 63
      meter.create_counter('a_counter', unit: long_unit)
      _(-> { meter.create_counter('b_counter', unit: long_unit + 'a') }).must_raise(INSTRUMENT_UNIT_ERROR)
    end

    it 'instrument description must be utf8mb3' do
      _(-> { meter.create_counter('a_counter', description: '💩'.dup) }).must_raise(INSTRUMENT_DESCRIPTION_ERROR)
      _(-> { meter.create_counter('b_counter', description: "\xc2".dup) }).must_raise(INSTRUMENT_DESCRIPTION_ERROR)
    end

    it 'instrument description must not exceed 1023 characters' do
      long_description = 'a' * 1023
      meter.create_counter('a_counter', description: long_description)
      _(-> { meter.create_counter('b_counter', description: long_description + 'a') }).must_raise(INSTRUMENT_DESCRIPTION_ERROR)
    end
  end
end
