# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require 'simplecov'
# # SimpleCov.start
# # SimpleCov.minimum_coverage 85

require 'opentelemetry-metrics-sdk'
require 'minitest/autorun'
require 'pry'

# reset_metrics_sdk is a test helper used to clear
# SDK configuration state between calls
def reset_metrics_sdk
  OpenTelemetry.instance_variable_set(
    :@meter_provider,
    OpenTelemetry::Internal::ProxyMeterProvider.new
  )

  OpenTelemetry.logger = Logger.new(File::NULL)
  OpenTelemetry.error_handler = nil
end
