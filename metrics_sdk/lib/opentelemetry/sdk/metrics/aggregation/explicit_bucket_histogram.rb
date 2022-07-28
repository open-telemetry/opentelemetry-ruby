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
          # The Default Value represents the following buckets:
          # (-inf, 0], (0, 5.0], (5.0, 10.0], (10.0, 25.0], (25.0, 50.0],
          # (50.0, 75.0], (75.0, 100.0], (100.0, 250.0], (250.0, 500.0],
          # (500.0, 1000.0], (1000.0, +inf)
          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze

          def initialize(
            boundaries: DEFAULT_BOUNDARIES,
            record_min_max: true
          )
            @data_points = {}
            @aggregation_temporality = :delta
            @boundaries = boundaries
            @record_min_max = record_min_max
          end

          def collect(start_time, end_time)
            hdps = @data_points.map do |_key, hdp|
              hdp.count = hdp.bucket_counts.sum
              hdp.start_time_unix_nano = start_time
              hdp.time_unix_nano = end_time
              hdp
            end
            @data_points.clear if @aggregation_temporality == :delta
            hdps
          end

          def update(amount, attributes)
            hdp = @data_points[attributes] || @data_points[attributes] = HistogramDataPoint.new(
              attributes,
              nil,                 # :start_time_unix_nano
              nil,                 # :time_unix_nano
              0,                   # :count
              0,                   # :sum
              empty_bucket_counts, # :bucket_counts
              @boundaries,         # :explicit_bounds
              nil,                 # :exemplars
              nil,                 # flags
              Float::INFINITY,     # :min
              -Float::INFINITY     # :max
            )

            if @record_min_max
              hdp.max = amount if amount > hdp.max
              hdp.min = amount if amount < hdp.min
            end

            hdp.sum += amount
            hdp.bucket_counts[bisect_left(@boundaries, amount)] += 1
            nil
          end

          private

          def empty_bucket_counts
            Array.new(@boundaries.size + 1, 0)
          end

          def bisect_left(boundaries, amount)
            low = 0
            high = boundaries.size
            while low < high
              mid = (low + high) / 2
              if boundaries[mid] < amount
                low = mid + 1
              else
                high = mid
              end
            end

            low
          end
        end
      end
    end
  end
end
