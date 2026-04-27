# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'benchmark/ips'
require 'opentelemetry-metrics-api'
require 'opentelemetry/sdk/metrics'

OpenTelemetry.logger = Logger.new(File::NULL)

Agg    = OpenTelemetry::SDK::Metrics::Aggregation
Ex     = OpenTelemetry::SDK::Metrics::Exemplar
Export = OpenTelemetry::SDK::Metrics::Export

def new_reader
  Export::InMemoryMetricPullExporter.new
end

def counter_with(exemplar_filter:, exemplar_reservoir: nil)
  meter = build_sdk_meter(exemplar_filter: exemplar_filter)
  meter.create_counter('bench.exemplar.counter', exemplar_reservoir: exemplar_reservoir)
end

def histogram_with(exemplar_filter:, exemplar_reservoir: nil)
  meter = build_sdk_meter(exemplar_filter: exemplar_filter)
  meter.create_histogram('bench.exemplar.histogram', exemplar_reservoir: exemplar_reservoir)
end

def build_sdk_meter(exemplar_filter: nil, views: [])
  provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
  provider.enable_exemplar_filter(exemplar_filter: exemplar_filter) if exemplar_filter
  views.each { |(name, opts)| provider.add_view(name, **opts) }
  provider.add_metric_reader(new_reader)
  provider.meter('bench')
end
