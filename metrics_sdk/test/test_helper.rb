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
  OpenTelemetry::SDK::Metrics::ForkHooks.instance_variable_set(:@fork_hooks_attached, false)
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

def create_meter
  ENV['OTEL_TRACES_EXPORTER'] = 'console'
  ENV['OTEL_METRICS_EXPORTER'] = 'none'
  OpenTelemetry::SDK.configure
  OpenTelemetry.meter_provider.add_metric_reader(metric_exporter)
  OpenTelemetry.meter_provider.exemplar_filter_on(exemplar_filter: exemplar_filter)
  OpenTelemetry.meter_provider.meter('SAMPLE_METER_NAME')
end

# Suppress warn-level logs about a missing OTLP exporter for traces
ENV['OTEL_TRACES_EXPORTER'] = 'none'

MAX_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_EXPONENT
MIN_NORMAL_EXPONENT = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MIN_NORMAL_EXPONENT
MAX_NORMAL_VALUE = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MAX_NORMAL_VALUE
MIN_NORMAL_VALUE = OpenTelemetry::SDK::Metrics::Aggregation::ExponentialHistogram::IEEE754::MIN_NORMAL_VALUE

def left_boundary(scale, inds)
  while scale > 0 && inds < -1022
    inds /= 2.to_f
    scale -= 1
  end

  result = 2.0**inds

  scale.times { result = Math.sqrt(result) }
  result
end

def right_boundary(scale, index)
  result = 2**index

  scale.abs.times do
    result *= result
  end

  result
end

def span_id_hex(span_id)
  span_id.unpack1('H*')
end

def trace_id_hex(trace_id)
  trace_id.unpack1('H*')
end
