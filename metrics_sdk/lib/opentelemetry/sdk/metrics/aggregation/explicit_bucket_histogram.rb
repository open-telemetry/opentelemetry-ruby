# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the ExplicitBucketHistogram aggregation
        # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#explicit-bucket-histogram-aggregation
        class ExplicitBucketHistogram
          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze
          private_constant :DEFAULT_BOUNDARIES

          # The default value for boundaries represents the following buckets:
          # (-inf, 0], (0, 5.0], (5.0, 10.0], (10.0, 25.0], (25.0, 50.0],
          # (50.0, 75.0], (75.0, 100.0], (100.0, 250.0], (250.0, 500.0],
          # (500.0, 1000.0], (1000.0, +inf)
          def initialize(
            aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative),
            boundaries: DEFAULT_BOUNDARIES,
            record_min_max: true
          )
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, default: :cumulative)
            @boundaries = boundaries && !boundaries.empty? ? boundaries.sort : nil
            @record_min_max = record_min_max
            @data_points = {}
          end

          def collect(start_time, end_time, data_points: nil)
            dp = data_points || @data_points
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              hdps = dp.values.map! do |hdp|
                hdp.start_time_unix_nano = start_time
                hdp.time_unix_nano = end_time
                hdp
              end
              dp.clear
              hdps
            else
              # Update timestamps and take a snapshot.
              dp.values.map! do |hdp|
                hdp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                hdp.time_unix_nano = end_time
                hdp = hdp.dup
                hdp.bucket_counts = hdp.bucket_counts.dup
                hdp
              end
            end
          end

          def update(amount, attributes, data_points: nil)
            dp = data_points || @data_points
            hdp = dp.fetch(attributes) do
              if @record_min_max
                min = Float::INFINITY
                max = -Float::INFINITY
              end

              dp[attributes] = HistogramDataPoint.new(
                attributes,
                nil,                 # :start_time_unix_nano
                nil,                 # :time_unix_nano
                0,                   # :count
                0,                   # :sum
                empty_bucket_counts, # :bucket_counts
                @boundaries,         # :explicit_bounds
                nil,                 # :exemplars
                min,                 # :min
                max                  # :max
              )
            end

            if @record_min_max
              hdp.max = amount if amount > hdp.max
              hdp.min = amount if amount < hdp.min
            end

            hdp.sum += amount
            hdp.count += 1
            if @boundaries
              bucket_index = @boundaries.bsearch_index { |i| i >= amount } || @boundaries.size
              hdp.bucket_counts[bucket_index] += 1
            end
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

          def empty_bucket_counts
            @boundaries ? Array.new(@boundaries.size + 1, 0) : nil
          end
        end
      end
    end
  end
end
