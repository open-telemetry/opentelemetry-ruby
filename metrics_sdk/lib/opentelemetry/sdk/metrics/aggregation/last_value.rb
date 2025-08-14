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
          def initialize
            @data_points = {}
          end

          def collect(start_time, end_time, data_points: nil)
            dp = data_points || @data_points
            ndps = dp.values.map! do |ndp|
              ndp.start_time_unix_nano = start_time
              ndp.time_unix_nano = end_time
              ndp
            end
            dp.clear
            ndps
          end

          def update(increment, attributes, data_points)
            dp = data_points || @data_points
            dp[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              increment,
              nil
            )
            nil
          end
        end
      end
    end
  end
end
