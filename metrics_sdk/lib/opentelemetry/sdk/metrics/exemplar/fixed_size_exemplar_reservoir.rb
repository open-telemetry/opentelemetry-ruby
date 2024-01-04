# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class FixedSizeExemplarReservoir < ExemplarReservoir
          MAX_BUCKET_SIZE = 1
          
          def initialize(max_size: nil)
            super()
            @max_size = max_size || MAX_BUCKET_SIZE
          end

          # MUST use an uniformly-weighted sampling algorithm based on the number of samples the reservoir
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            span_context = current_span_context(context)
            if @exemplars.size >= @max_size
              rand_index = rand(0..@max_size-1)
              @exemplars[rand_index] = Exemplar.new(value, timestamp, attributes, span_context.hex_span_id, span_context.hex_trace_id)
              nil
            else
              super(value: value, timestamp: timestamp, attributes: attributes, context: context)
            end
          end

          def collect(attributes: nil, aggregation_temporality: nil)
            super(attributes: attributes, aggregation_temporality: aggregation_temporality)
          end
        end
      end
    end
  end
end
