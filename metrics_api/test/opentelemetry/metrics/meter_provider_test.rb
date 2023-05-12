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

    it 'returns an instance of Meter' do
      meter_provider = build_meter_provider

      assert(meter_provider.meter('test', version: '1.0.0').is_a?(OpenTelemetry::Metrics::Meter))
    end
  end

  def build_meter_provider
    OpenTelemetry::Metrics::MeterProvider.new
  end
end
