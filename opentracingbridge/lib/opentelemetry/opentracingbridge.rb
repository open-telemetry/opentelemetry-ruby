# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentracing'

module OpenTelemetry
  # OpenTracingBridge provides a means of converting
  # from OpenTelemetry to OpenTracing objects
  module OpenTracingBridge
  end
end

require 'opentelemetry/opentracingbridge/scope_manager'
require 'opentelemetry/opentracingbridge/scope'
require 'opentelemetry/opentracingbridge/span_context'
require 'opentelemetry/opentracingbridge/span'
require 'opentelemetry/opentracingbridge/tracer'
require 'opentelemetry/opentracingbridge/version'
