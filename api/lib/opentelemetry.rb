# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context'
require 'opentelemetry/distributed_context'
require 'opentelemetry/metrics'
require 'opentelemetry/resources'
require 'opentelemetry/trace'
require 'opentelemetry/version'

# OpenTelemetry provides global accessors for telemetry objects @see Trace::Tracer, @see Metrics::Meter
# and @see DistributedContext::Manager.
module OpenTelemetry
  extend self

  attr_writer :tracer, :meter, :distributed_context_manager

  def tracer
    @tracer ||= Trace::Tracer.new
  end

  def meter
    @meter ||= Metrics::Meter.new
  end

  def distributed_context_manager
    @distributed_context_manager ||= DistributedContext::Manager.new
  end
end
