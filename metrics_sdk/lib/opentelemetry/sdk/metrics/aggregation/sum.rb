# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the Sum aggregation
        # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#sum-aggregation
        class Sum
          def initialize(aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative), monotonic: false)
            @aggregation_temporality = aggregation_temporality.to_sym == :delta ? AggregationTemporality.delta : AggregationTemporality.cumulative
            @monotonic = monotonic
            @data_points = {}
          end

          def collect(start_time, end_time, data_points: nil)
            dp = data_points || @data_points
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              ndps = dp.values.map! do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end
              dp.clear
              ndps
            else
              # Update timestamps and take a snapshot.
              dp.values.map! do |ndp|
                ndp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                ndp.time_unix_nano = end_time
                ndp.dup
              end
            end
          end

          def monotonic?
            @monotonic
          end

          # no double exporting so when view exist, then we only export the metric_data processed by view
          def update(increment, attributes, data_points: nil)
            return if @monotonic && increment < 0

            dp = data_points || @data_points
            ndp = dp[attributes] || dp[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              nil
            )

            ndp.value += increment
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end
        end
      end
    end
  end
end
