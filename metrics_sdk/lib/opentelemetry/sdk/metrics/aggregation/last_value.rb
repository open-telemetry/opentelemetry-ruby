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
          # if no reservoir pass from instrument, then use this empty reservoir to avoid no method found error
          DEFAULT_RESERVOIR = Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
          private_constant :DEFAULT_RESERVOIR

          def initialize(exemplar_reservoir: DEFAULT_RESERVOIR)
            @exemplar_reservoir = exemplar_reservoir
          end

          def collect(start_time, end_time, data_points)
            ndps = data_points.values.map! do |ndp|
              ndp.start_time_unix_nano = start_time
              ndp.time_unix_nano = end_time
              ndp
            end
            data_points.clear
            ndps
          end

          def update(increment, attributes, data_points)
            data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              increment,
              @exemplar_reservoir.collect(attributes: attributes, aggregation_temporality: :delta)
            )
            nil
          end
        end
      end
    end
  end
end
