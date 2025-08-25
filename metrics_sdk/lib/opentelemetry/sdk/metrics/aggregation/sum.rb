# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'set'

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the Sum aggregation
        class Sum # rubocop:disable Metrics/ClassLength
          OVERFLOW_ATTRIBUTE_SET = { 'otel.metric.overflow' => true }.freeze

          def initialize(aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative), monotonic: false, instrument_kind: nil)
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, instrument_kind: instrument_kind, default: :cumulative)
            @monotonic = monotonic
            @overflow_started = false
            @pre_overflow_attributes = ::Set.new if @aggregation_temporality.cumulative?
          end

          def collect(start_time, end_time, data_points, cardinality_limit)
            if @aggregation_temporality.delta?
              collect_delta(start_time, end_time, data_points, cardinality_limit)
            else
              collect_cumulative(start_time, end_time, data_points, cardinality_limit)
            end
          end

          def update(increment, attributes, data_points, cardinality_limit)
            return if @monotonic && increment < 0

            # Check if we already have this attribute set
            if data_points.key?(attributes)
              data_points[attributes].value += increment
              return
            end

            # For cumulative: track pre-overflow attributes
            if @aggregation_temporality.cumulative?
              if !@overflow_started && data_points.size < cardinality_limit
                @pre_overflow_attributes.add(attributes)
                create_new_data_point(attributes, increment, data_points)
                return
              elsif @pre_overflow_attributes.include?(attributes)
                # Allow pre-overflow attributes even after overflow started
                create_new_data_point(attributes, increment, data_points)
                return
              end
            elsif data_points.size < cardinality_limit
              # For delta: simple size check
              create_new_data_point(attributes, increment, data_points)
              return
            end

            # Overflow case: aggregate into overflow data point
            @overflow_started = true
            overflow_ndp = data_points[OVERFLOW_ATTRIBUTE_SET] || data_points[OVERFLOW_ATTRIBUTE_SET] = NumberDataPoint.new(
              OVERFLOW_ATTRIBUTE_SET,
              nil,
              nil,
              0,
              nil
            )
            overflow_ndp.value += increment
          end

          def monotonic?
            @monotonic
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

          def create_new_data_point(attributes, increment, data_points)
            data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              increment,
              nil
            )
          end

          def collect_cumulative(start_time, end_time, data_points, cardinality_limit)
            # Cumulative: return all data points (including overflow if present)
            result = data_points.values.map do |ndp|
              ndp.start_time_unix_nano ||= start_time
              ndp.time_unix_nano = end_time
              ndp.dup
            end

            # Apply cardinality limit if we have more points than limit
            apply_cardinality_limit_to_result(result, cardinality_limit)
          end

          def collect_delta(start_time, end_time, data_points, cardinality_limit)
            # Delta: can choose arbitrary subset each collection
            all_points = data_points.values

            if all_points.size <= cardinality_limit
              # All points fit within limit
              result = all_points.map do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end
            else
              # Apply cardinality limit by choosing subset + overflow
              selected_points = choose_delta_subset(all_points, cardinality_limit - 1)
              remaining_points = all_points - selected_points

              result = selected_points.map do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end

              # Create overflow point for remaining
              if remaining_points.any?
                overflow_value = remaining_points.sum(&:value)
                overflow_point = NumberDataPoint.new(
                  OVERFLOW_ATTRIBUTE_SET,
                  start_time,
                  end_time,
                  overflow_value,
                  nil
                )
                result << overflow_point
              end
            end

            data_points.clear
            result
          end

          def apply_cardinality_limit_to_result(result, cardinality_limit)
            return result if result.size <= cardinality_limit

            # For cumulative, we should have already enforced this in update()
            # But as safety net, keep first N points
            result.first(cardinality_limit)
          end

          def choose_delta_subset(points, count)
            # Strategy: keep points with highest absolute values
            points.sort_by { |point| -point.value.abs }.first(count)
          end
        end
      end
    end
  end
end
