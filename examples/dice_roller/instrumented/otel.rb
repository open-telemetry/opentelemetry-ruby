# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry-metrics-sdk'
require 'opentelemetry-logs-sdk'
require 'opentelemetry/instrumentation/sinatra'
require 'opentelemetry/instrumentation/logger'
require 'opentelemetry-exporter-otlp-metrics'
require 'opentelemetry-exporter-otlp-logs'

# ---------------------------------------------------------------------------
# Exporters
#
# By default we export to stdout/console so the app works out of the box.
# Set OTEL_TRACES_EXPORTER=otlp, OTEL_METRICS_EXPORTER=otlp, or
# OTEL_LOGS_EXPORTER=otlp to send to an OTLP-compatible backend.
# ---------------------------------------------------------------------------
ENV['OTEL_TRACES_EXPORTER']  ||= 'console'
ENV['OTEL_METRICS_EXPORTER'] ||= 'console'
ENV['OTEL_LOGS_EXPORTER']    ||= 'console'

# Enable OTel internal diagnostic logging via OTEL_LOG_LEVEL env var.
# e.g. OTEL_LOG_LEVEL=debug ruby app.rb

# ---------------------------------------------------------------------------
# Configure the OpenTelemetry SDK
# ---------------------------------------------------------------------------
OpenTelemetry::SDK.configure do |c|
  # Resource attributes (service.name etc.) are read from env vars:
  #   OTEL_SERVICE_NAME=dice_roller
  #   OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production,...

  # Auto-instrument Sinatra (HTTP server spans) and Ruby Logger (log bridge)
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.use 'OpenTelemetry::Instrumentation::Logger'
end

# ---------------------------------------------------------------------------
# Metrics SDK — add a console reader so metrics are visible without a backend
# ---------------------------------------------------------------------------
case ENV['OTEL_METRICS_EXPORTER']
when 'otlp'
  otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(
    OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(exporter: otlp_metric_exporter)
  )
else
  console_metric_exporter = OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(console_metric_exporter)
end

# ---------------------------------------------------------------------------
# Logs SDK — wire up a console exporter and bridge Ruby's Logger
# ---------------------------------------------------------------------------
logs_logger_provider = OpenTelemetry::SDK::Logs::LoggerProvider.new
case ENV['OTEL_LOGS_EXPORTER']
when 'otlp'
  log_processor = OpenTelemetry::SDK::Logs::Export::BatchLogRecordProcessor.new(
    OpenTelemetry::Exporter::OTLP::Logs::LogsExporter.new
  )
  logs_logger_provider.add_log_record_processor(log_processor)
else
  log_processor = OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(
    OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter.new
  )
  logs_logger_provider.add_log_record_processor(log_processor)
end
OpenTelemetry.logger_provider = logs_logger_provider

at_exit do
  OpenTelemetry.meter_provider.shutdown
  logs_logger_provider.shutdown
end
