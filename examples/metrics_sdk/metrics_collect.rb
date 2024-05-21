# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem "opentelemetry-api"
  gem "opentelemetry-common"
  gem "opentelemetry-sdk"

  gem 'opentelemetry-metrics-api', path: '../../metrics_api'
  gem 'opentelemetry-metrics-sdk', path: '../../metrics_sdk'
end

require 'opentelemetry/sdk'
require 'opentelemetry-metrics-sdk'

OpenTelemetry::SDK.configure

console_metric_exporter = OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter.new

OpenTelemetry.meter_provider.add_metric_reader(console_metric_exporter)

meter = OpenTelemetry.meter_provider.meter("SAMPLE_METER_NAME")

histogram = meter.create_histogram('histogram', unit: 'smidgen', description: 'desscription')

histogram.record(123, attributes: {'foo' => 'bar'})

OpenTelemetry.meter_provider.metric_readers.each(&:pull)
OpenTelemetry.meter_provider.shutdown
