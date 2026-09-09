# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/metrics'
require 'opentelemetry/metrics/version'
require 'opentelemetry/internal/proxy_instrument'
require 'opentelemetry/internal/proxy_meter_provider'
require 'opentelemetry/internal/proxy_meter'
require 'opentelemetry/internal/global_meter_provider'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# Requiring this gem makes the Metrics API available to instrumentation through
# {OpenTelemetry::Internal.meter_provider}.
