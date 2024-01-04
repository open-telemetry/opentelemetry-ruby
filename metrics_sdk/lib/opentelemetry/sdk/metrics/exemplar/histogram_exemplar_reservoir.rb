# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # same as AlignedHistogramBucketExemplarReservoir
        class HistogramExemplarReservoir < ExemplarReservoir

          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze
          private_constant :DEFAULT_BOUNDARIES

          def initialize(boundaries: nil)
            super()
            @boundaries = boundaries || DEFAULT_BOUNDARIES
          end

          # TODO: align with the requirements of alignedhistogrambucketexemplarreservoir for offering
          # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#alignedhistogrambucketexemplarreservoir
          # Assumption: each boundary should have one exemplar measurement
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            bucket = find_histogram_bucket(value)
            if bucket < @boundaries.size
              span_context = current_span_context(context)
              @exemplars[bucket] = Exemplar.new(value, timestamp, attributes, span_context.hex_span_id, span_context.hex_trace_id)
            end
          end

          # return Exemplar
          def collect(attributes: nil, aggregation_temporality: nil)
            super(attributes: attributes, aggregation_temporality: aggregation_temporality)
          end

          def find_histogram_bucket(value)
            @boundaries.bsearch_index { |i| i >= value } || @boundaries.size
          end
        end
      end
    end
  end
end