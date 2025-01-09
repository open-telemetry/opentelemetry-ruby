# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'opentelemetry-logs-api', path: '../../logs_api'
  gem 'opentelemetry-logs-sdk', path: '../../logs_sdk'
  gem 'opentelemetry-exporter-otlp-logs', path: '../../exporter/otlp-logs'
end

require 'opentelemetry-logs-sdk'
require 'opentelemetry/exporter/otlp_logs'

# Create a LoggerProvider
logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new
# Create a batching processor configured to export to the OTLP exporter
processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new)
# Add the processor to the LoggerProvider
logger_provider.add_log_record_processor(processor)
# Access a Logger for your library from your LoggerProvider
logger = logger_provider.logger(name: 'my_app_or_gem', version: '0.1.0')

# Use your Logger to  emit a log record
logger.on_emit(
  timestamp: Time.now,
  severity_text: 'INFO',
  body: 'Thuja plicata',
  attributes: { 'cedar' => true },
)

logger_provider.shutdown
