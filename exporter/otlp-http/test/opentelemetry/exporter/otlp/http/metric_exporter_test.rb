# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

describe OpenTelemetry::Exporter::OTLP::HTTP::MetricExporter do
  SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS
  FAILURE = OpenTelemetry::SDK::Metrics::Export::FAILURE

  it 'integrates with collector' do
    WebMock.disable_net_connect!(allow: 'localhost')
    OpenTelemetry::SDK.configure
    meter = OpenTelemetry.meter_provider.meter('test')
    instrument = meter.create_counter('b_counter')

    il = OpenTelemetry::SDK::InstrumentationLibrary.new('test_scope', 'v0.0.1')
    r = OpenTelemetry::SDK::Resources::Resource.telemetry_sdk
    il2 = OpenTelemetry::SDK::InstrumentationLibrary.new('secondary_scope', 'v0.0.2')
    r = OpenTelemetry::SDK::Resources::Resource.telemetry_sdk

    ms1 = create_metric_stream(name: 'test_instrument_a', resource: r, instrumentation_library: il)
    ms1.update(OpenTelemetry::Metrics::Measurement.new(11, { 'foo' => 'bar' }))
    ms2 = create_metric_stream(name: 'test_instrument_b', resource: r, instrumentation_library: il2)
    ms2.update(OpenTelemetry::Metrics::Measurement.new(11, { 'foo' => 'bar' }))

    exporter = OpenTelemetry::Exporter::OTLP::HTTP::MetricExporter.new(endpoint: 'http://localhost:4318/v1/metrics', compression: 'gzip')
    result = exporter.export([ms1,ms2])
    _(result).must_equal(SUCCESS)
  end

  def create_metric_stream(name: 'test_instrument', description: 'a wonderful instrument', unit: 'cm', instrument_kind: :counter, resource: OpenTelemetry::SDK::Resources::Resource.telemetry_sdk, instrumentation_library: OpenTelemetry::SDK::InstrumentationLibrary.new('test_scope', 'v0.0.1'))
    OpenTelemetry::SDK::Metrics::State::MetricStream.new(
      name,
      description,
      unit,
      instrument_kind,
      resource,
      instrumentation_library,
    )
  end
end
