# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Metrics::MeterProvider do
  describe '#meter' do
    it 'requires a name' do
      meter_provider = build_meter_provider

      _(-> { meter_provider.meter }).must_raise(ArgumentError)
    end

    it 'optionally accepts a version' do
      meter_provider = build_meter_provider
      meter = meter_provider.meter('name', version: '1.0')

      _(meter).must_be_instance_of(OpenTelemetry::Metrics::Meter)
    end

    it 'optionally accepts attributes' do
      meter_provider = build_meter_provider
      meter = meter_provider.meter('name', attributes: { 'key' => 'value' })

      _(meter).must_be_instance_of(OpenTelemetry::Metrics::Meter)
    end

    it 'treats nil attributes the same as no attributes' do
      meter_provider = build_meter_provider
      meter1 = meter_provider.meter('name')
      meter2 = meter_provider.meter('name', attributes: nil)

      _(meter1).must_equal(meter2)
    end

    it 'returns an instance of Meter' do
      meter_provider = build_meter_provider

      assert_kind_of(OpenTelemetry::Metrics::Meter, meter_provider.meter('test', version: '1.0.0'))
    end
  end

  def build_meter_provider
    OpenTelemetry::Metrics::MeterProvider.new
  end
end
