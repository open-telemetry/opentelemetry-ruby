# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'opentelemetry-sdk', path: '../../sdk'
  gem 'opentelemetry-logs-api', path: '../../logs_api'
  gem 'opentelemetry-logs-sdk', path: '../../logs_sdk'
end

require 'opentelemetry-sdk'
require 'opentelemetry-logs-sdk'

# Export logs to the console
ENV['OTEL_LOGS_EXPORTER'] = 'console'

# Configure SDK with defaults, this will apply the OTEL_LOGS_EXPORTER env var
OpenTelemetry::SDK.configure

# Access a Logger for your library from the LoggerProvider configured by the OpenTelemetry API
logger = OpenTelemetry.logger_provider.logger(name: 'my_app_or_gem', version: '0.1.0')

# Use your Logger to emit a log record
logger.on_emit(
  timestamp: Time.now,
  severity_text: 'INFO',
  body: 'Thuja plicata',
  attributes: { 'cedar' => true },
)
