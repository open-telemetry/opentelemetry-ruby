# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context'
require 'opentelemetry/distributed_context'
require 'opentelemetry/internal'
require 'opentelemetry/metrics'
require 'opentelemetry/resources'
require 'opentelemetry/trace'
require 'opentelemetry/version'

# OpenTelemetry provides global accessors for telemetry objects
module OpenTelemetry
  extend self

  attr_writer :tracer, :meter, :distributed_context_manager

  # @return [Object, Trace::Tracer] registered tracer or a default no-op
  #   implementation of the tracer
  def tracer
    @tracer ||= Trace::Tracer.new
  end

  # @return [Object, Metrics::Meter] registered meter or a default no-op
  #   implementation of the meter
  def meter
    @meter ||= Metrics::Meter.new
  end

  # @return [Object, DistributedContext::Manager] registered distributed
  #   context manager or a default no-op implementation of the manager
  def distributed_context_manager
    @distributed_context_manager ||= DistributedContext::Manager.new
  end
end
