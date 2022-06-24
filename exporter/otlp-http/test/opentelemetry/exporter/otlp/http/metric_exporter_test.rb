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

    exporter = OpenTelemetry::Exporter::OTLP::HTTP::MetricExporter.new(endpoint: 'http://localhost:4318/v1/metrics', compression: 'gzip')
    metric_reader = OpenTelemetry::SDK::Metrics::Export::MetricReader.new(exporter)
    OpenTelemetry.meter_provider.add_metric_reader(metric_reader)

    instrument.add(1, attributes: { 'foo' => 'bar', 'bar' => 'foo' })

    result = exporter.export(metric_reader.collect)
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
