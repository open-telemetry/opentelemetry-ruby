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
require 'opentelemetry/resource/detector'

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

  # Merge resource detectors: process (built-in), container, and env vars
  # The SDK already includes process and telemetry_sdk detectors by default.
  # We add the container detector to detect container.id when running in containers.
  c.resource = OpenTelemetry::SDK::Resources::Resource.default.merge(
    OpenTelemetry::Resource::Detector::Container.detect
  )

  # Auto-instrument Sinatra (HTTP server spans) and Ruby Logger (log bridge)
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.use 'OpenTelemetry::Instrumentation::Logger'
end

# ---------------------------------------------------------------------------
# Metrics and Logs Configuration
# ---------------------------------------------------------------------------
# NOTE: Metrics and logs providers are automatically configured by
# OpenTelemetry::SDK.configure above based on the OTEL_METRICS_EXPORTER
# and OTEL_LOGS_EXPORTER environment variables. The SDK handles:
#
# - Creating the meter_provider and logger_provider
# - Setting up appropriate exporters (console, otlp, etc.)
# - Adding metric readers and log record processors
#
# However, we still need to explicitly shutdown the providers at exit
# to ensure all telemetry data is flushed before the application terminates.
at_exit do
  OpenTelemetry.meter_provider.shutdown
  OpenTelemetry.logger_provider.shutdown
end
