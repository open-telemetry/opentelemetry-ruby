# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK do
  describe '#configure' do
    before { reset_metrics_sdk }

    it 'upgrades the API MeterProvider, Meters, and Instruments' do
      meter_provider = OpenTelemetry.meter_provider
      meter = meter_provider.meter('test')
      instrument = meter.create_counter('a_counter')

      # Calls before the SDK is configured return Proxy implementations
      _(meter_provider).must_be_instance_of OpenTelemetry::Internal::ProxyMeterProvider
      _(meter).must_be_instance_of OpenTelemetry::Internal::ProxyMeter
      _(instrument).must_be_instance_of OpenTelemetry::Internal::ProxyInstrument

      OpenTelemetry::SDK.configure

      # Proxy implementations now have their delegates set
      _(meter_provider.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::SDK::Metrics::MeterProvider
      _(meter.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::SDK::Metrics::Meter
      _(instrument.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Counter

      # Calls after the SDK is configured now return the SDK implementations directly
      _(OpenTelemetry.meter_provider).must_be_instance_of OpenTelemetry::SDK::Metrics::MeterProvider
      _(OpenTelemetry.meter_provider.meter('test')).must_be_instance_of OpenTelemetry::SDK::Metrics::Meter
      _(OpenTelemetry.meter_provider.meter('test').create_counter('b_counter')).must_be_instance_of OpenTelemetry::SDK::Metrics::Instrument::Counter
    end

    it 'sends the original configuration error to the error handler' do
      received_exception = nil
      received_message = nil

      OpenTelemetry.error_handler = lambda do |exception: nil, message: nil|
        received_exception = exception
        received_message = message
      end

      OpenTelemetry::SDK.configure(&:do_something)

      _(received_exception).must_be_instance_of OpenTelemetry::SDK::ConfigurationError
      _(received_message).must_match(/unexpected configuration error due to undefined method `do_something/)
    end
  end
end
