# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentracing'

module OpenTelemetry
  # OpenTracingShim provides a means of converting
  # from OpenTelemetry to OpenTracing objects
  module OpenTracingShim
  end
end

require 'opentelemetry/opentracingshim/scope_manager_shim'
require 'opentelemetry/opentracingshim/scope_shim'
require 'opentelemetry/opentracingshim/span_context_shim'
require 'opentelemetry/opentracingshim/span_shim'
require 'opentelemetry/opentracingshim/tracer_shim'
require 'opentelemetry/opentracingshim/version'
