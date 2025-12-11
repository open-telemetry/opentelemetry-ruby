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
          attr_reader :exemplar_reservoir

          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze
          private_constant :DEFAULT_BOUNDARIES

          # The default value for boundaries represents the following buckets:
          # (-inf, 0], (0, 5.0], (5.0, 10.0], (10.0, 25.0], (25.0, 50.0],
          # (50.0, 75.0], (75.0, 100.0], (100.0, 250.0], (250.0, 500.0],
          # (500.0, 1000.0], (1000.0, +inf)
          def initialize(
            aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative),
            boundaries: DEFAULT_BOUNDARIES,
            record_min_max: true,
            exemplar_reservoir: nil
          )
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, default: :cumulative)
            @boundaries = boundaries && !boundaries.empty? ? boundaries.sort : nil
            @record_min_max = record_min_max

            # Create reservoir with matching boundaries if not provided
            # Per spec: Explicit bucket histogram SHOULD use AlignedHistogramBucketExemplarReservoir
            @exemplar_reservoir = exemplar_reservoir || create_default_reservoir(@boundaries)
          end

          def collect(start_time, end_time, data_points)
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              hdps = data_points.values.map! do |hdp|
                hdp.start_time_unix_nano = start_time
                hdp.time_unix_nano = end_time
                hdp.exemplars = @exemplar_reservoir.collect(attributes: hdp.attributes, aggregation_temporality: @aggregation_temporality)
                hdp
              end
              data_points.clear
              hdps
            else
              # Update timestamps and take a snapshot.
              data_points.values.map! do |hdp|
                hdp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                hdp.time_unix_nano = end_time
                hdp.exemplars = @exemplar_reservoir.collect(attributes: hdp.attributes, aggregation_temporality: @aggregation_temporality)
                hdp = hdp.dup
                hdp.bucket_counts = hdp.bucket_counts.dup
                hdp
              end
            end
          end

          def update(amount, attributes, data_points)
            hdp = data_points.fetch(attributes) do
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
                @exemplar_reservoir.collect(attributes: attributes, aggregation_temporality: @aggregation_temporality), # :exemplars
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

          def create_default_reservoir(boundaries)
            if boundaries && !boundaries.empty?
              # Per spec: Explicit bucket histogram with more than 1 bucket SHOULD use AlignedHistogramBucketExemplarReservoir
              Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: boundaries)
            else
              # Fallback to SimpleFixedSizeExemplarReservoir if no boundaries
              Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
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
