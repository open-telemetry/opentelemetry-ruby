# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the Sum aggregation
        class Sum
          include StreamScopedStorage

          OVERFLOW_ATTRIBUTE_SET = { 'otel.metric.overflow' => true }.freeze
          attr_reader :exemplar_reservoir

          # if no reservior pass from instrument, then use this empty reservior to avoid no method found error
          DEFAULT_RESERVOIR = Metrics::Exemplar::SimpleFixedSizeExemplarReservoir.new
          private_constant :DEFAULT_RESERVOIR

          def initialize(aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :cumulative),
                         monotonic: false,
                         instrument_kind: nil,
                         exemplar_reservoir: nil)
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, instrument_kind: instrument_kind, default: :cumulative)
            @monotonic = monotonic
            @exemplar_reservoir = exemplar_reservoir || DEFAULT_RESERVOIR
            @exemplar_reservoir_storage = new_stream_storage
            @observed_values = new_stream_storage
          end

          # Returns the current sum data points, clearing them for delta temporality.
          def collect(start_time, end_time, data_points)
            stream_exemplar_reservoir_storage = @exemplar_reservoir_storage[data_points]

            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              ndps = data_points.values.map! do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
                reservoir = stream_exemplar_reservoir_storage[ndp.attributes]
                ndp.exemplars = reservoir&.collect(attributes: ndp.attributes, aggregation_temporality: @aggregation_temporality.temporality)
                ndp
              end
              data_points.clear
              ndps
            else
              # Update timestamps and take a snapshot.
              data_points.values.map! do |ndp|
                ndp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                ndp.time_unix_nano = end_time
                reservoir = stream_exemplar_reservoir_storage[ndp.attributes]
                ndp.exemplars = reservoir&.collect(attributes: ndp.attributes, aggregation_temporality: @aggregation_temporality.temporality)
                ndp.dup
              end
            end
          end

          # Adds increment to the sum for the given attributes.
          def update(increment, attributes, data_points, cardinality_limit, exemplar_offer: false)
            return if @monotonic && increment < 0

            ndp = find_or_create_data_point(attributes, data_points, cardinality_limit)
            update_number_data_point(ndp, increment, data_points, exemplar_offer: exemplar_offer)
            nil
          end

          # Records the current total observed by an asynchronous instrument for the given attributes.
          #
          # Asynchronous instruments report absolute values, so only the change since the previous
          # observation of these attributes is added. A cumulative sum therefore reports the latest
          # observation, and a delta sum reports the change since the last collection. A monotonic
          # sum that observes a lower value treats it as a counter reset.
          def observe(value, attributes, data_points, cardinality_limit, exemplar_offer: false)
            return if @monotonic && value < 0

            observed_values = @observed_values[data_points]
            previous = observed_values.fetch(attributes, 0)
            observed_values[attributes] = value
            ndp = find_or_create_data_point(attributes, data_points, cardinality_limit)

            if @monotonic && value < previous
              # Counter reset: a cumulative sum starts over from the new value at the next
              # collection, and a delta sum reports everything counted since the reset.
              ndp.start_time_unix_nano = nil if @aggregation_temporality.cumulative?
              previous = 0 if @aggregation_temporality.delta?
            end

            reservior_update(ndp.attributes, value, exemplar_offer, data_points)
            ndp.value += value - previous
            nil
          end

          # Returns whether the sum is required to be non-decreasing.
          def monotonic?
            @monotonic
          end

          # Returns the configured aggregation temporality (:delta or :cumulative).
          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

          def find_or_create_data_point(attributes, data_points, cardinality_limit)
            if data_points.key?(attributes)
              data_points[attributes]
            elsif data_points.size >= cardinality_limit - 1
              data_points[OVERFLOW_ATTRIBUTE_SET] || create_new_data_point(OVERFLOW_ATTRIBUTE_SET, data_points)
            else
              create_new_data_point(attributes, data_points)
            end
          end

          def create_new_data_point(attributes, data_points)
            data_points[attributes] = NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              0,
              nil
            )
          end

          def update_number_data_point(ndp, increment, stream_key, exemplar_offer: false)
            reservior_update(ndp.attributes, increment, exemplar_offer, stream_key)
            ndp.value += increment
          end

          def reservior_update(attributes, increment, exemplar_offer, stream_key)
            reservoir = @exemplar_reservoir_storage[stream_key][attributes]
            unless reservoir
              reservoir = @exemplar_reservoir.dup
              reservoir.reset
              @exemplar_reservoir_storage[stream_key][attributes] = reservoir
            end

            return unless exemplar_offer

            reservoir.offer(value: increment,
                            timestamp: OpenTelemetry::Common::Utilities.time_in_nanoseconds,
                            attributes: attributes,
                            context: OpenTelemetry::Context.current)
          end
        end
      end
    end
  end
end
