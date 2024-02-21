# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the Drop aggregation
        class Drop
          attr_reader :aggregation_temporality

          def initialize(aggregation_temporality: :delta)
            @aggregation_temporality = aggregation_temporality
          end

          def collect(start_time, end_time, data_points)
            data_points.values.map!(&:dup)
          end

          def update(increment, attributes, data_points)
            data_points[attributes] = NumberDataPoint.new(
              {},
              0,
              0,
              0,
              0
            )
            nil
          end
        end
      end
    end
  end
end
