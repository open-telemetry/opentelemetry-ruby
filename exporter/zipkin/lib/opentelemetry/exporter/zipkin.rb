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
    # Zipkin contains SpanExporter implementations for the Zipkin collector in v2 format.
    module Zipkin
    end
  end
end

$LOAD_PATH.push(File.dirname(__FILE__) + '/../../../thrift/gen-rb')

require 'opentelemetry-semantic_conventions'
require 'opentelemetry/sdk'
require 'opentelemetry/common'
require 'opentelemetry/exporter/zipkin/transformer'
require 'opentelemetry/exporter/zipkin/exporter'
require 'opentelemetry/exporter/zipkin/version'
