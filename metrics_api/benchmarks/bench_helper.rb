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

ATTRS_MEDIUM = { 'http.method' => 'GET', 'http.status_code' => 200, 'http.route' => '/api/users' }.freeze

def new_reader
  Export::InMemoryMetricPullExporter.new
end

def build_sdk_meter(exemplar_filter: nil, views: [])
  provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
  provider.enable_exemplar_filter(exemplar_filter: exemplar_filter) if exemplar_filter
  views.each { |(name, opts)| provider.add_view(name, **opts) }
  provider.add_metric_reader(new_reader)
  provider.meter('bench')
end
