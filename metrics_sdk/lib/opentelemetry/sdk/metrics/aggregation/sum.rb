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
          def initialize
            @aggregation_temporality = :delta

            @data_points = {}
          end

          def collect(start_time, end_time)
            @data_points.each_value do |ndp|
              ndp.start_time_unix_nano = start_time
              ndp.time_unix_nano = end_time
            end
            ndps = @data_points.values
            if @aggregation_temporality == :delta
              @data_points.clear
            else
              ndps = ndps.map(&:dup)
            end
            ndps
          end

          def update(increment, attributes)
            ndp = @data_points[attributes] || @data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              nil
            )

            ndp.value += increment
            nil
          end
        end
      end
    end
  end
end
