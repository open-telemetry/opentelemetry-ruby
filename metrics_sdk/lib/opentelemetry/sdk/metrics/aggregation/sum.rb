# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        class Sum
          def initialize
            @aggregation_temporality = :delta

            @data_points = {}
            @mutex = Mutex.new
          end

          def collect
            dp = @data_points.dup
            @data_points.clear if @aggregation_temporality == :delta
            dp
          end

          def update(increment, attributes)
            @data_points[attributes] = if @data_points[attributes]
                                         @data_points[attributes] + increment
                                       else
                                         increment
                                       end
          end
        end
      end
    end
  end
end
