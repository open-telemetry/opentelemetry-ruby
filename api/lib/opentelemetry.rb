# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

require 'opentelemetry/error'
require 'opentelemetry/context'
require 'opentelemetry/context_utils'
require 'opentelemetry/correlation_context'
require 'opentelemetry/internal'
require 'opentelemetry/instrumentation'
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

  attr_writer :tracer_provider, :meter_provider, :correlations

  attr_accessor :logger

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

  # @return [Object, CorrelationContext::Manager] registered
  #   correlation context manager or a default no-op implementation of the
  #   manager.
  def correlations
    @correlations ||= CorrelationContext::Manager.new
  end

  # @return [Context::Propagation::Propagation] an instance of the propagation API
  def propagation
    @propagation ||= Context::Propagation::Propagation.new
  end

  self.logger = Logger.new(STDOUT)
end
