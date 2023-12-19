# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if RUBY_ENGINE == 'ruby'
  require 'simplecov'
  SimpleCov.start
end

require 'opentelemetry-test-helpers'
require 'opentelemetry/exporter/otlp_metrics'
require 'minitest/autorun'
require 'webmock/minitest'

OpenTelemetry.logger = Logger.new(File::NULL)

module MockSum
  def collect(start_time, end_time)
    start_time = 1_699_593_427_329_946_585 # rubocop:disable Lint/ShadowedArgument
    end_time   = 1_699_593_427_329_946_586 # rubocop:disable Lint/ShadowedArgument
    super
  end
end

OpenTelemetry::SDK::Metrics::Aggregation::Sum.prepend(MockSum)
OpenTelemetry::SDK::Metrics::Aggregation::ExplicitBucketHistogram.prepend(MockSum)

def create_metrics_data(name: '', description: '', unit: '', instrument_kind: :counter, resource: nil,
                        instrumentation_scope: OpenTelemetry::SDK::InstrumentationScope.new('', 'v0.0.1'),
                        data_points: nil, aggregation_temporality: :delta, start_time_unix_nano: 0, time_unix_nano: 0)
  data_points ||= [OpenTelemetry::SDK::Metrics::Aggregation::NumberDataPoint.new(attributes: {}, start_time_unix_nano: 0, time_unix_nano: 0, value: 1, exemplars: nil)]
  resource    ||= OpenTelemetry::SDK::Resources::Resource.telemetry_sdk

  OpenTelemetry::SDK::Metrics::State::MetricData.new(name, description, unit, instrument_kind,
                                                     resource, instrumentation_scope, data_points,
                                                     aggregation_temporality, start_time_unix_nano, time_unix_nano)
end
