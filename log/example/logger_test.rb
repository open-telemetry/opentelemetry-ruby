#!/usr/bin/env ruby

require 'semantic_logger'
require 'opentelemetry/sdk'
require 'opentelemetry/sdk/log'
require 'opentelemetry/sdk/log/appender/semantic_logger_appender'

OpenTelemetry::SDK.configure do |c|
  c.configure_logging_sdk
end

appender = OpenTelemetry::SDK::Log::Appender::SemanticLoggerAppender.new(
  log_emitter: OpenTelemetry.log_emitter_provider.log_emitter
)

SemanticLogger.on_log do |log|
  # log processing happens on a different thread for semantic_logger, so
  # we need to capture the current span in a callback before the log is
  # actually handled by semantic_logger
  log.set_context(:opentelemetry_span, OpenTelemetry::Trace.current_span)
end
SemanticLogger.add_appender(appender: appender)

logger = SemanticLogger['test-logger-1']

logger.info 'test 123'

OpenTelemetry.tracer_provider.tracer('test-tracer').in_span('test-span') do
  logger.info 'test from span', { additional: 'tags' }
end
