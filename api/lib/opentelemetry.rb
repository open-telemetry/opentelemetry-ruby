# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

require 'opentelemetry/error'
require 'opentelemetry/context'
require 'opentelemetry/baggage'
require_relative './opentelemetry/instrumentation'
require 'opentelemetry/metrics'
require 'opentelemetry/trace'
require 'opentelemetry/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
module OpenTelemetry
  extend self

  attr_writer :tracer_provider, :meter_provider, :propagation, :baggage,
              :logger, :error_handler

  # @return [Object, Logger] configured Logger or a default STDOUT Logger.
  def logger
    @logger ||= Logger.new(STDOUT, level: ENV['OTEL_LOG_LEVEL'] || Logger::INFO)
  end

  # @return [Callable] configured error handler or a default that logs the
  #   exception and message at ERROR level.
  def error_handler
    @error_handler ||= ->(exception: nil, message: nil) { logger.error("OpenTelemetry error: #{[message, exception&.message].compact.join(' - ')}") }
  end

  # Handles an error by calling the configured error_handler.
  #
  # @param [optional Exception] exception The exception to be handled
  # @param [optional String] message An error message.
  def handle_error(exception: nil, message: nil)
    error_handler.call(exception: exception, message: message)
  end

  # @return [Object, Trace::TracerProvider] registered tracer provider or a
  #   default no-op implementation of the tracer provider.
  def tracer_provider
    @tracer_provider ||= Trace::TracerProvider.new
  end

  # @return [Object, Metrics::MeterProvider] registered meter provider or a
  #   default no-op implementation of the meter provider.
  def meter_provider
    @meter_provider ||= Metrics::MeterProvider.new
  end

  # @return [Instrumentation::Registry] registry containing all known
  #  instrumentation
  def instrumentation_registry
    @instrumentation_registry ||= Instrumentation::Registry.new
  end

  # @return [Object, Baggage::NoopManager] registered
  #   baggage manager or a default no-op implementation of the
  #   manager.
  def baggage
    @baggage ||= Baggage::NoopManager.new
  end

  # @return [Context::Propagation::Propagator] a propagator instance
  def propagation
    @propagation ||= Context::Propagation::Propagator.new(
      Context::Propagation::NoopInjector.new,
      Context::Propagation::NoopExtractor.new
    )
  end
end
