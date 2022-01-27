# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::MetricsSDK do
  describe '#configure' do
    after do
      # Ensure we don't leak custom loggers and error handlers to other tests
      OpenTelemetry.logger = Logger.new(File::NULL)
      OpenTelemetry.error_handler = nil
    end

    it 'upgrades the API MeterProvider, Meters, and Instruments' do
      meter_provider = OpenTelemetry.meter_provider
      meter = meter_provider.meter("test")
      instrument = meter.create_counter("a_counter")

      OpenTelemetry::MetricsSDK.configure

      _(meter_provider.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::MetricsSDK::Metrics::MeterProvider
      _(meter.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::MetricsSDK::Metrics::Meter
      _(instrument.instance_variable_get(:@delegate)).must_be_instance_of OpenTelemetry::MetricsSDK::Metrics::Instrument::Counter
    end

    it 'sends the original configuration error to the error handler' do
      received_exception = nil
      received_message = nil

      OpenTelemetry.error_handler = lambda do |exception: nil, message: nil|
        received_exception = exception
        received_message = message
      end

      OpenTelemetry::MetricsSDK.configure do |config|
        config.do_something
      end

      _(received_exception).must_be_instance_of OpenTelemetry::MetricsSDK::ConfigurationError
      _(received_message).must_match(/unexpected configuration error due to undefined method `do_something/)
    end
  end
end
