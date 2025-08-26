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

          def collect(start_time, end_time, data_points)
            ndps = data_points.values.map! do |ndp|
              ndp.start_time_unix_nano = start_time
              ndp.time_unix_nano = end_time
              ndp
            end
            data_points.clear
            ndps
          end

          def update(increment, attributes, data_points, cardinality_limit)
            # Check if we already have this attribute set
            ndp = if data_points.key?(attributes)
                    data_points[attributes]
                  elsif data_points.size >= cardinality_limit
                    data_points[OVERFLOW_ATTRIBUTE_SET] || create_new_data_point(OVERFLOW_ATTRIBUTE_SET, data_points)
                  else
                    create_new_data_point(attributes, data_points)
                  end

            update_number_data_point(ndp, increment)
            nil
          end

          private

          def create_new_data_point(attributes, data_points)
            data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              nil
            )
          end

          def update_number_data_point(ndp, increment)
            ndp.value = increment
          end
        end
      end
    end
  end
end
