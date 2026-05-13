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
            @exemplar_reservoir = exemplar_reservoir || Metrics::Exemplar::AlignedHistogramBucketExemplarReservoir.new(boundaries: @boundaries)
            @exemplar_reservoir_storage = {}
          end

          def collect(start_time, end_time, data_points)
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              hdps = data_points.values.map! do |hdp|
                hdp.start_time_unix_nano = start_time
                hdp.time_unix_nano = end_time
                reservoir = @exemplar_reservoir_storage[hdp.attributes]
                hdp.exemplars = reservoir&.collect(attributes: hdp.attributes, aggregation_temporality: @aggregation_temporality)
                hdp
              end
              data_points.clear
              hdps
            else
              # Update timestamps and take a snapshot.
              data_points.values.map! do |hdp|
                hdp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                hdp.time_unix_nano = end_time
                reservoir = @exemplar_reservoir_storage[hdp.attributes]
                hdp.exemplars = reservoir&.collect(attributes: hdp.attributes, aggregation_temporality: @aggregation_temporality)
                hdp = hdp.dup
                hdp.bucket_counts = hdp.bucket_counts.dup
                hdp
              end
            end
          end

          def update(amount, attributes, data_points, cardinality_limit, exemplar_offer: false)
            hdp = if data_points.key?(attributes)
                    data_points[attributes]
                  elsif data_points.size >= cardinality_limit
                    data_points[OVERFLOW_ATTRIBUTE_SET] || create_new_data_point(OVERFLOW_ATTRIBUTE_SET, data_points)
                  else
                    create_new_data_point(attributes, data_points)
                  end

            update_histogram_data_point(hdp, amount, exemplar_offer: exemplar_offer)
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

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

          def update_histogram_data_point(hdp, amount, exemplar_offer: false)
            reservior_update(hdp.attributes, amount, exemplar_offer)

            if @record_min_max
              hdp.max = amount if amount > hdp.max
              hdp.min = amount if amount < hdp.min
            end

            hdp.sum += amount
            hdp.count += 1
            return unless @boundaries

            bucket_index = @boundaries.bsearch_index { |i| i >= amount } || @boundaries.size
            hdp.bucket_counts[bucket_index] += 1
          end

          def reservior_update(attributes, amount, exemplar_offer)
            reservoir = @exemplar_reservoir_storage[attributes]
            unless reservoir
              reservoir = @exemplar_reservoir.dup
              reservoir.reset
              @exemplar_reservoir_storage[attributes] = reservoir
            end

            return unless exemplar_offer

            reservoir.offer(value: amount,
                            timestamp: OpenTelemetry::Common::Utilities.time_in_nanoseconds,
                            attributes: attributes,
                            context: OpenTelemetry::Context.current)
          end

          def empty_bucket_counts
            @boundaries ? Array.new(@boundaries.size + 1, 0) : nil
          end
        end
      end
    end
  end
end
