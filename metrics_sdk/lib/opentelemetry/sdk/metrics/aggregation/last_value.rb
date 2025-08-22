# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the LastValue aggregation
        class LastValue
          OVERFLOW_ATTRIBUTE_SET = { 'otel.metric.overflow' => true }.freeze

          def initialize
            @overflow_started = false
          end

          def collect(start_time, end_time, data_points, cardinality_limit: 2000)
            # Apply cardinality limit by choosing subset + overflow for LastValue
            all_points = data_points.values

            if all_points.size <= cardinality_limit
              # All points fit within limit
              ndps = all_points.map! do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end
            else
              # Choose most recent values (LastValue behavior)
              selected_points = choose_last_value_subset(all_points, cardinality_limit - 1)
              remaining_points = all_points - selected_points

              ndps = selected_points.map do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end

              # Create overflow point with the last remaining value
              if remaining_points.any?
                # For LastValue, use the most recent remaining value
                overflow_value = remaining_points.max_by(&:time_unix_nano)&.value || 0
                overflow_point = NumberDataPoint.new(
                  OVERFLOW_ATTRIBUTE_SET,
                  start_time,
                  end_time,
                  overflow_value,
                  nil
                )
                ndps << overflow_point
              end
            end

            data_points.clear
            ndps
          end

          def update(increment, attributes, data_points, cardinality_limit: 2000)
            # Check if we already have this attribute set
            if data_points.key?(attributes)
              # Update existing data point (LastValue behavior - replace)
              data_points[attributes] = NumberDataPoint.new(
                attributes,
                nil,
                nil,
                increment,
                nil
              )
              return
            end

            # Check cardinality limit for new attribute sets
            if data_points.size >= cardinality_limit
              # Overflow: aggregate into overflow data point
              @overflow_started = true
              data_points[OVERFLOW_ATTRIBUTE_SET] = NumberDataPoint.new(
                OVERFLOW_ATTRIBUTE_SET,
                nil,
                nil,
                increment,
                nil
              )
              return
            end

            # Normal case - create new data point
            data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              increment,
              nil
            )
            nil
          end

          private

          def choose_last_value_subset(points, count)
            # For LastValue, prefer most recently updated points
            # Since we don't have timestamp tracking, use array order as proxy
            points.last(count)
          end
        end
      end
    end
  end
end
