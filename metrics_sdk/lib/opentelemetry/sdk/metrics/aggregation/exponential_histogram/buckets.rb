# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        module ExponentialHistogram
          class Buckets
            attr_accessor :index_start, :index_end, :index_base
            attr_reader :counts

            def initialize
              @counts = [0]
              @index_base = 0
              @index_start = 0
              @index_end = 0
            end

            def grow(needed, max_size)
              size = @counts.size
              bias = @index_base - @index_start
              old_positive_limit = size - bias

              new_size = [2**Math.log2(needed).ceil, max_size].min

              new_positive_limit = new_size - bias

              tmp = Array.new(new_size, 0)
              tmp[new_positive_limit..-1] = @counts[old_positive_limit..-1]
              tmp[0...old_positive_limit] = @counts[0...old_positive_limit]
              @counts = tmp
            end

            def offset
              @index_start
            end

            def get_offset_counts
              bias = @index_base - @index_start
              @counts[-bias..-1] + @counts[0...-bias]
            end
            alias_method :counts, :get_offset_counts

            def length
              return 0 if @counts.empty?
              return 0 if @index_end == @index_start && self[0] == 0

              @index_end - @index_start + 1
            end

            def get_bucket(key)
              bias = @index_base - @index_start

              key += @counts.size if key < bias
              key -= bias

              @counts[key]
            end

            def downscale(amount)
              bias = @index_base - @index_start

              if bias != 0
                @index_base = @index_start
                @counts.reverse!
                @counts = @counts[0...bias].reverse + @counts[bias..-1].reverse
              end

              size = 1 + @index_end - @index_start
              each = 1 << amount
              inpos = 0
              outpos = 0
              pos = @index_start

              while pos <= @index_end
                mod = pos % each
                mod += each if mod < 0

                inds = mod

                while inds < each && inpos < size
                  if outpos != inpos
                    @counts[outpos] += @counts[inpos]
                    @counts[inpos] = 0
                  end

                  inpos += 1
                  pos   += 1
                  inds  += 1
                end

                outpos += 1
              end

              @index_start >>= amount
              @index_end >>= amount
              @index_base = @index_start
            end

            def increment_bucket(bucket_index, increment = 1)
              @counts[bucket_index] += increment
            end
          end
        end
      end
    end
  end
end

