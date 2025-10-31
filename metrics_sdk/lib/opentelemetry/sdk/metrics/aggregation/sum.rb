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
          # if no reservior pass from instrument, then use this empty reservior to avoid no method found error
          DEFAULT_RESERVOIR = Metrics::Exemplar::FixedSizeExemplarReservoir.new
          private_constant :DEFAULT_RESERVOIR

          def initialize(aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative),
                         monotonic: false,
                         instrument_kind: nil,
                         exemplar_reservoir: DEFAULT_RESERVOIR)
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, instrument_kind: instrument_kind, default: :cumulative)
            @monotonic = monotonic
            @exemplar_reservoir = exemplar_reservoir
          end

          def collect(start_time, end_time, data_points)
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              ndps = data_points.values.map! do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                ndp
              end
              data_points.clear
              ndps
            else
              # Update timestamps and take a snapshot.
              data_points.values.map! do |ndp|
                ndp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                ndp.time_unix_nano = end_time
                ndp.dup
              end
            end
          end

          def monotonic?
            @monotonic
          end

          def update(increment, attributes, data_points)
            return if @monotonic && increment < 0

            ndp = data_points[attributes] || data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              # will this cause the reservoir overloaded with old exemplars?
              @exemplar_reservoir.collect(attributes: attributes, aggregation_temporality: @aggregation_temporality) # exemplar
            )

            ndp.value += increment
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end
        end
      end
    end
  end
end
