# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require 'simplecov'
# # SimpleCov.start
# # SimpleCov.minimum_coverage 85

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-test-helpers'
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

def with_test_logger
  log_stream = StringIO.new
  original_logger = OpenTelemetry.logger
  OpenTelemetry.logger = ::Logger.new(log_stream)
  yield log_stream
ensure
  OpenTelemetry.logger = original_logger
end

# Suppress warn-level logs about a missing OTLP exporter for traces
ENV['OTEL_TRACES_EXPORTER'] = 'none'
