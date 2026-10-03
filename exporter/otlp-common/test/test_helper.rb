# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'dotenv'
Dotenv.load(File.expand_path('.env', __dir__))

require 'simplecov'
SimpleCov.start

require 'opentelemetry-metrics-sdk'
require 'opentelemetry/sdk'
require 'opentelemetry-test-helpers'
require 'opentelemetry-exporter-otlp-common'

require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new(File::NULL)

def create_metrics_data(name: '', description: '', unit: '', instrument_kind: :counter, resource: nil,
                        instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('', 'v0.0.1'),
                        data_points: nil, aggregation_temporality: :delta, start_time_unix_nano: 0, time_unix_nano: 0)
  data_points ||= [OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new(attributes: {}, start_time_unix_nano: 0, time_unix_nano: 0, value: 1, exemplars: nil)]
  resource    ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk

  OpenTelemetry::SDK::Metrics::State::MetricData.new(name, description, unit, instrument_kind,
                                                     resource, instrumentation_scope, data_points,
                                                     aggregation_temporality, start_time_unix_nano, time_unix_nano)
end
