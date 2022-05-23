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
      # GRPC contains the implementation for the OTLP over GRPC exporter
      module GRPC
      end
    end
  end
end

require 'opentelemetry/exporter/otlp/grpc/trace_exporter'
require 'opentelemetry/exporter/otlp/grpc/version'
