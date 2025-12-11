# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # AlignedHistogramBucketExemplarReservoir
        #
        # This Exemplar reservoir stores at most one exemplar per histogram bucket.
        # It uses reservoir sampling within each bucket to ensure uniform distribution
        # of exemplars across the value range.
        #
        # This is the recommended reservoir for Explicit Bucket Histogram aggregation.
        class AlignedHistogramBucketExemplarReservoir < ExemplarReservoir
          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze
          private_constant :DEFAULT_BOUNDARIES

          # @param boundaries [Array<Numeric>] The bucket boundaries for the histogram
          def initialize(boundaries: nil)
            super()
            @boundaries = boundaries || DEFAULT_BOUNDARIES
            @num_measurements_seen = Array.new(@boundaries.size + 1, 0)
          end

          # Offers a measurement to the reservoir for potential sampling
          #
          # @param value [Numeric] The measurement value
          # @param timestamp [Integer] The timestamp in nanoseconds
          # @param attributes [Hash] The complete set of attributes
          # @param context [Context] The OpenTelemetry context
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            bucket = find_histogram_bucket(value)

            return if bucket > @boundaries.size

            span_context = current_span_context(context)
            num_seen = @num_measurements_seen[bucket]

            if num_seen == 0 || rand(0..num_seen) == 0
              @exemplars[bucket] = Exemplar.new(
                value,
                timestamp,
                attributes,
                span_context.span_id,
                span_context.trace_id
              )
            end

            @num_measurements_seen[bucket] += 1
            nil
          end

          # Collects accumulated exemplars and optionally resets state
          #
          # @param attributes [Hash] The attributes (currently unused, for future filtering)
          # @param aggregation_temporality [Symbol] :delta or :cumulative
          # @return [Array<Exemplar>] The collected exemplars
          def collect(attributes: nil, aggregation_temporality: nil)
            exemplars = super(attributes: attributes, aggregation_temporality: aggregation_temporality)
            @num_measurements_seen = Array.new(@boundaries.size + 1, 0) if aggregation_temporality == :delta
            exemplars
          end

          private

          # Finds the bucket index for a given value
          #
          # @param value [Numeric] The measurement value
          # @return [Integer] The bucket index (0 to boundaries.size)
          def find_histogram_bucket(value)
            @boundaries.bsearch_index { |boundary| boundary >= value } || @boundaries.size
          end
        end
      end
    end
  end
end
