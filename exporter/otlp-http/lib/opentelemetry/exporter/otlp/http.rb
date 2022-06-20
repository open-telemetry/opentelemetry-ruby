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
    module OTLP
      # HTTP contains the implementation for the OTLP over HTTP exporters
      module HTTP
      end
    end
  end
end

require 'opentelemetry/exporter/otlp/http/trace_exporter'
require 'opentelemetry/exporter/otlp/http/metric_exporter'
require 'opentelemetry/exporter/otlp/http/version'
