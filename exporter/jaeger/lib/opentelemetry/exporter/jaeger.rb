# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  module Exporter
    # Jaeger contains SpanExporter implementations for the Jaeger agent and collector.
    module Jaeger
    end
  end
end

$LOAD_PATH.push(File.dirname(__FILE__) + '/../../../thrift/gen-rb')

require 'agent'
require 'collector'
require 'opentelemetry/sdk'
require 'opentelemetry/common'
require 'socket'
require 'opentelemetry/exporter/jaeger/encoder'
require 'opentelemetry/exporter/jaeger/transport'
require 'opentelemetry/exporter/jaeger/agent_exporter'
require 'opentelemetry/exporter/jaeger/collector_exporter'
require 'opentelemetry/exporter/jaeger/version'
