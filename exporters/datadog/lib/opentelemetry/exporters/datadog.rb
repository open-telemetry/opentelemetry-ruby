# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require_relative './datadog/exporter.rb'
# require_relative './datadog/version.rb'
# require_relative './datadog/datadog_span_processor.rb'
# require_relative './datadog/propagator.rb'
# require_relative './datadog_probability_sampler'
require 'opentelemetry/exporters/datadog/exporter'
require 'opentelemetry/exporters/datadog/version'
require 'opentelemetry/exporters/datadog/datadog_span_processor'
require 'opentelemetry/exporters/datadog/propagator'
require 'opentelemetry/exporters/datadog/datadog_probability_sampler'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
end
