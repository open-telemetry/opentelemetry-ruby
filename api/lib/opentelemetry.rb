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

# OpenTelemetry provides global accessors for telemetry objects @see Tracer, @see Meter
# and @see DistributedContextManager.
module OpenTelemetry
  extend self

  attr_writer :tracer, :meter, :distributed_context_manager

  def tracer
    @tracer || Tracer
  end

  def meter
    @meter || Meter
  end

  def distributed_context_manager
    @distributed_context_manager || DistributedContextManager
  end
end
