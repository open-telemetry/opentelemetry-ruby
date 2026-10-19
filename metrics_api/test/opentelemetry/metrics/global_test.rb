# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/metrics/global'

describe 'OpenTelemetry.meter_provider' do
  after do
    OpenTelemetry::Internal.instance_variable_set(
      :@meter_provider,
      OpenTelemetry::Internal::ProxyMeterProvider.new
    )
  end

  it 'reads the provider held in the internal slot' do
    provider = OpenTelemetry::Metrics::MeterProvider.new
    OpenTelemetry::Internal.meter_provider = provider

    assert_same(OpenTelemetry.meter_provider, provider)
  end

  it 'writes through to the internal slot' do
    provider = OpenTelemetry::Metrics::MeterProvider.new
    OpenTelemetry.meter_provider = provider

    assert_same(OpenTelemetry::Internal.meter_provider, provider)
  end

  it 'can be required after a provider is already registered' do
    provider = OpenTelemetry::Metrics::MeterProvider.new
    OpenTelemetry::Internal.meter_provider = provider
    require 'opentelemetry/metrics/global'

    assert_same(OpenTelemetry.meter_provider, provider)
  end
end
