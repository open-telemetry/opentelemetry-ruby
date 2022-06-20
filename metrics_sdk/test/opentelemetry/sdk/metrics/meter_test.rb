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
end
