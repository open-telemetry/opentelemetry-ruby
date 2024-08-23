# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry do
  after do
    # TODO: After Metrics SDK is incorporated into OpenTelemetry SDK, move this
    # to OpenTelemetry::TestHelpers.reset_opentelemetry
    OpenTelemetry.instance_variable_set(
      :@meter_provider,
      OpenTelemetry::Internal::ProxyMeterProvider.new
    )
  end

  describe '#meter_provider and #meter_provider=' do
    it 'initializes with a global instance of ProxyMeterProvider' do
      assert(OpenTelemetry.meter_provider.is_a?(OpenTelemetry::Internal::ProxyMeterProvider))
    end

    it 'sets global MeterProvider to the given meter_provider' do
      new_meter_provider = OpenTelemetry::Metrics::MeterProvider.new

      OpenTelemetry.meter_provider = new_meter_provider

      assert_same(OpenTelemetry.meter_provider, new_meter_provider)
    end

    describe 'when global MeterProvider is an instance of Internal::ProxyMeterProvider' do
      it 'sets ProxyMeterProvider#delegate to the given meter_provider and logs a debug message' do
        proxy_meter_provider = OpenTelemetry.meter_provider
        new_meter_provider = OpenTelemetry::Metrics::MeterProvider.new

        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          OpenTelemetry.meter_provider = new_meter_provider

          assert_same(proxy_meter_provider.instance_variable_get(:@delegate), new_meter_provider)
          assert_same(OpenTelemetry.meter_provider, new_meter_provider)
          assert(log_stream.string.match?(/Upgrading default proxy meter provider to #{new_meter_provider.class}/i))
        end
      end
    end
  end
end
