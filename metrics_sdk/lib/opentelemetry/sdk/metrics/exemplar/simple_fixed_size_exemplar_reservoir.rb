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
            @max_size = max_size || DEFAULT_SIZE
            reset
          end

          # MUST use a uniformly-weighted sampling algorithm based on the number of samples the reservoir has seen
          # Uses reservoir sampling algorithm: https://en.wikipedia.org/wiki/Reservoir_sampling
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            # exemplar = Exemplar.new(attributes, value, timestamp, span_context.span_id, span_context.trace_id)
            exemplar_bucket = Metrics::Exemplar::ExemplarBucket.new
            exemplar_bucket.offer(value: value, time_unix_nano: timestamp, attributes: attributes, context: context)

            if @num_measurements_seen < @max_size
              @exemplar_buckets[@num_measurements_seen] = exemplar_bucket
            else
              bucket_index = rand(0..@num_measurements_seen)
              @exemplar_buckets[bucket_index] = exemplar_bucket if bucket_index < @max_size
            end

            @num_measurements_seen += 1
            nil
          end

          # Reset measurement counter on collection for delta temporality
          def collect(attributes: nil, aggregation_temporality: nil)
            exemplars = []
            @exemplar_buckets.each do |bucket|
              exemplars << bucket.collect(point_attributes: attributes)
            end
            reset if aggregation_temporality == :delta
            exemplars.compact!
            # puts "exemplars: #{exemplars.inspect}"
            exemplars
          end

          def reset
            @exemplar_buckets = Array.new(@max_size) { ExemplarBucket.new }
            @num_measurements_seen = 0
          end
        end
      end
    end
  end
end
