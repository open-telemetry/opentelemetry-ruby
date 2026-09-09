# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Internal do
  after do
    # TODO: After Metrics SDK is incorporated into OpenTelemetry SDK, move this
    # to OpenTelemetry::TestHelpers.reset_opentelemetry
    OpenTelemetry::Internal.instance_variable_set(
      :@meter_provider,
      OpenTelemetry::Internal::ProxyMeterProvider.new
    )
  end

  describe 'requiring the gem' do
    it 'does not define the top-level meter provider accessor' do
      # Asserted in a subprocess because requiring opentelemetry/metrics/global
      # anywhere in this suite defines the accessor for the whole process.
      script = 'require "opentelemetry-metrics-api"; exit(OpenTelemetry.respond_to?(:meter_provider) ? 1 : 0)'

      assert(system(RbConfig.ruby, '-e', script), 'requiring opentelemetry-metrics-api defined OpenTelemetry.meter_provider')
    end

    it 'defines the internal meter provider that instrumentation reads' do
      script = 'require "opentelemetry-metrics-api"; exit(OpenTelemetry::Internal.meter_provider ? 0 : 1)'

      assert(system(RbConfig.ruby, '-e', script))
    end
  end

  describe '#meter_provider and #meter_provider=' do
    it 'initializes with a global instance of ProxyMeterProvider' do
      assert_kind_of(OpenTelemetry::Internal::ProxyMeterProvider, OpenTelemetry::Internal.meter_provider)
    end

    it 'sets global MeterProvider to the given meter_provider' do
      new_meter_provider = OpenTelemetry::Metrics::MeterProvider.new

      OpenTelemetry::Internal.meter_provider = new_meter_provider

      assert_same(OpenTelemetry::Internal.meter_provider, new_meter_provider)
    end

    describe 'when global MeterProvider is an instance of Internal::ProxyMeterProvider' do
      it 'sets ProxyMeterProvider#delegate to the given meter_provider and logs a debug message' do
        proxy_meter_provider = OpenTelemetry::Internal.meter_provider
        new_meter_provider = OpenTelemetry::Metrics::MeterProvider.new

        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry::Internal.meter_provider = new_meter_provider

          assert_same(proxy_meter_provider.instance_variable_get(:@delegate), new_meter_provider)
          assert_same(OpenTelemetry::Internal.meter_provider, new_meter_provider)
          assert_match(/Upgrading default proxy meter provider to #{new_meter_provider.class}/i, log_stream.string)
        end
      end
    end
  end
end
