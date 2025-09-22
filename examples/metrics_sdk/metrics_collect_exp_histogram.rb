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

# this example manually configures the exporter, turn off automatic configuration
ENV['OTEL_METRICS_EXPORTER'] = 'none'

OpenTelemetry::SDK.configure

console_metric_exporter = OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter.new

OpenTelemetry.meter_provider.add_metric_reader(console_metric_exporter)

OpenTelemetry.meter_provider.add_view('*exponential*', aggregation: OpenTelemetry::SDK::Metrics::Aggregation::ExponentialBucketHistogram.new(aggregation_temporality: :cumulative, max_scale: 20), type: :histogram, unit: 'smidgen')

meter = OpenTelemetry.meter_provider.meter("SAMPLE_METER_NAME")

exponential_histogram = meter.create_histogram('test_exponential_histogram', unit: 'smidgen', description: 'a small amount of something')
(1..10).each do |v|
  val = v ** 2
  exponential_histogram.record(val, attributes: { 'lox' => 'xol' })
end

OpenTelemetry.meter_provider.metric_readers.each(&:pull)
OpenTelemetry.meter_provider.shutdown
