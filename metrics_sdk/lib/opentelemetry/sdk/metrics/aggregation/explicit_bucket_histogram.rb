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
          OVERFLOW_ATTRIBUTE_SET = { 'otel.metric.overflow' => true }.freeze
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
            @overflow_started = false
          end

          def collect(start_time, end_time, data_points, cardinality_limit: 2000)
            all_points = data_points.values

            # Apply cardinality limit
            if all_points.size <= cardinality_limit
              result = process_all_points(all_points, start_time, end_time)
            else
              result = process_with_cardinality_limit(all_points, start_time, end_time, cardinality_limit)
            end

            data_points.clear if @aggregation_temporality.delta?
            result
          end

          def update(amount, attributes, data_points, cardinality_limit: 2000)
            # Check if we already have this attribute set
            if data_points.key?(attributes)
              hdp = data_points[attributes]
            else
              # Check cardinality limit for new attribute sets
              if data_points.size >= cardinality_limit
                # Overflow: aggregate into overflow data point
                @overflow_started = true
                hdp = data_points[OVERFLOW_ATTRIBUTE_SET] || create_overflow_data_point(data_points)
              else
                # Normal case - create new data point
                hdp = create_new_data_point(attributes, data_points)
              end
            end

            # Update the histogram data point
            update_histogram_data_point(hdp, amount)
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

          def process_all_points(all_points, start_time, end_time)
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              all_points.map! do |hdp|
                hdp.start_time_unix_nano = start_time
                hdp.time_unix_nano = end_time
                hdp
              end
            else
              # Update timestamps and take a snapshot.
              all_points.map! do |hdp|
                hdp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                hdp.time_unix_nano = end_time
                hdp = hdp.dup
                hdp.bucket_counts = hdp.bucket_counts.dup
                hdp
              end
            end
          end

          def process_with_cardinality_limit(all_points, start_time, end_time, cardinality_limit)
            # Choose subset of histograms (prefer those with higher counts)
            selected_points = choose_histogram_subset(all_points, cardinality_limit - 1)
            remaining_points = all_points - selected_points

            result = process_all_points(selected_points, start_time, end_time)

            # Create overflow histogram by merging remaining points
            if remaining_points.any?
              overflow_point = merge_histogram_points(remaining_points, start_time, end_time)
              result << overflow_point
            end

            result
          end

          def choose_histogram_subset(points, count)
            # Strategy: keep histograms with highest counts (most data)
            points.sort_by { |hdp| -hdp.count }.first(count)
          end

          def merge_histogram_points(points, start_time, end_time)
            # Create a merged histogram with overflow attributes
            merged_bucket_counts = empty_bucket_counts

            merged = HistogramDataPoint.new(
              OVERFLOW_ATTRIBUTE_SET,
              start_time,
              end_time,
              0,   # count
              0.0, # sum
              merged_bucket_counts,
              @boundaries,
              nil, # exemplars
              Float::INFINITY,   # min
              -Float::INFINITY   # max
            )

            # Merge all remaining points into the overflow point
            points.each do |hdp|
              merged.count += hdp.count
              merged.sum += hdp.sum
              merged.min = [merged.min, hdp.min].min if hdp.min
              merged.max = [merged.max, hdp.max].max if hdp.max

              # Merge bucket counts
              if merged_bucket_counts && hdp.bucket_counts
                hdp.bucket_counts.each_with_index do |count, index|
                  merged_bucket_counts[index] += count
                end
              end
            end

            merged
          end

          def create_overflow_data_point(data_points)
            if @record_min_max
              min = Float::INFINITY
              max = -Float::INFINITY
            end

            data_points[OVERFLOW_ATTRIBUTE_SET] = HistogramDataPoint.new(
              OVERFLOW_ATTRIBUTE_SET,
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

          def create_new_data_point(attributes, data_points)
            if @record_min_max
              min = Float::INFINITY
              max = -Float::INFINITY
            end

            data_points[attributes] = HistogramDataPoint.new(
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

          def update_histogram_data_point(hdp, amount)
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
          end

          def empty_bucket_counts
            @boundaries ? Array.new(@boundaries.size + 1, 0) : nil
          end
        end
      end
    end
  end
end
