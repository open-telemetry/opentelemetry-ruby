# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'etc'

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        # SimpleFixedSizeExemplarReservoir
        class SimpleFixedSizeExemplarReservoir < ExemplarReservoir
          # Default to number of CPUs for better concurrent performance, fallback to 1
          DEFAULT_SIZE = begin
            Etc.nprocessors
          rescue StandardError
            1
          end

          def initialize(max_size: nil)
            super()
            @max_size = max_size || DEFAULT_SIZE
            @num_measurements_seen = 0
          end

          # MUST use a uniformly-weighted sampling algorithm based on the number of samples the reservoir has seen
          # Uses reservoir sampling algorithm: https://en.wikipedia.org/wiki/Reservoir_sampling
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            span_context = current_span_context(context)
            exemplar = Exemplar.new(value, timestamp, attributes, span_context.hex_span_id, span_context.hex_trace_id)

            if @num_measurements_seen < @max_size
              @exemplars[@num_measurements_seen] = exemplar
            else
              bucket = rand(0..@num_measurements_seen)
              @exemplars[bucket] = exemplar if bucket < @max_size
            end

            @num_measurements_seen += 1
            nil
          end

          # Reset measurement counter on collection for delta temporality
          def collect(attributes: nil, aggregation_temporality: nil)
            exemplars = super(attributes: attributes, aggregation_temporality: aggregation_temporality)
            @num_measurements_seen = 0 if aggregation_temporality == :delta
            exemplars
          end
        end
      end
    end
  end
end
