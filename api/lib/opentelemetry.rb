# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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

  attr_writer :tracer_provider, :meter_provider, :baggage

  DEFAULT_LOG_LEVEL = Logger::INFO
  private_constant :DEFAULT_LOG_LEVEL

  def logger
    return @@logger if defined?(@@logger)

    self.logger = Logger.new(STDOUT, level: ENV['OTEL_LOG_LEVEL'] || DEFAULT_LOG_LEVEL)
  end

  def logger=(logger)
    class_variable_set :@@logger, logger
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

  # @return [Object, Baggage::Manager] registered
  #   baggage manager or a default no-op implementation of the
  #   manager.
  def baggage
    @baggage ||= Baggage::Manager.new
  end

  # @return [Context::Propagation::Propagation] an instance of the propagation API
  def propagation
    @propagation ||= Context::Propagation::Propagation.new
  end
end
