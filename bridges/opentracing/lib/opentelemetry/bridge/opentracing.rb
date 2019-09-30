# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentracing'
require 'opentelemetry'

module OpenTelemetry
  module Bridge
    # OpenTracing Bridge provides a means of converting
    # from OpenTelemetry to OpenTracing objects
    module OpenTracing
    end
  end
end

require 'opentelemetry/bridge/opentracing/scope_manager'
require 'opentelemetry/bridge/opentracing/scope'
require 'opentelemetry/bridge/opentracing/span_context'
require 'opentelemetry/bridge/opentracing/span'
require 'opentelemetry/bridge/opentracing/tracer'
require 'opentelemetry/bridge/opentracing/version'
