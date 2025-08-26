# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'exponential_histogram/buckets'
require_relative 'exponential_histogram/log2e_scale_factor'
require_relative 'exponential_histogram/ieee_754'
require_relative 'exponential_histogram/logarithm_mapping'
require_relative 'exponential_histogram/exponent_mapping'

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the {https://opentelemetry.io/docs/specs/otel/metrics/data-model/#exponentialhistogram ExponentialBucketHistogram} aggregation
        class ExponentialBucketHistogram # rubocop:disable Metrics/ClassLength
          OVERFLOW_ATTRIBUTE_SET = { 'otel.metric.overflow' => true }.freeze

          # relate to min max scale: https://opentelemetry.io/docs/specs/otel/metrics/sdk/#support-a-minimum-and-maximum-scale
          DEFAULT_SIZE  = 160
          DEFAULT_SCALE = 20
          MAX_SCALE = 20
          MIN_SCALE = -10
          MIN_MAX_SIZE = 2
          MAX_MAX_SIZE = 16_384

          # The default boundaries are calculated based on default max_size and max_scale values
          def initialize(
            aggregation_temporality: ENV.fetch('OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE', :delta),
            max_size: DEFAULT_SIZE,
            max_scale: DEFAULT_SCALE,
            record_min_max: true,
            zero_threshold: 0
          )
            @aggregation_temporality = AggregationTemporality.determine_temporality(aggregation_temporality: aggregation_temporality, default: :delta)
            @record_min_max = record_min_max
            @min            = Float::INFINITY
            @max            = -Float::INFINITY
            @sum            = 0
            @count          = 0
            @zero_threshold = zero_threshold
            @zero_count     = 0
            @size           = validate_size(max_size)
            @scale          = validate_scale(max_scale)

            @mapping = new_mapping(@scale)
          end

          def collect(start_time, end_time, data_points)
            if @aggregation_temporality.delta?
              # Set timestamps and 'move' data point values to result.
              hdps = data_points.values.map! do |hdp|
                hdp.start_time_unix_nano = start_time
                hdp.time_unix_nano = end_time
                hdp
              end
              data_points.clear
              hdps
            else
              # Update timestamps and take a snapshot.
              data_points.values.map! do |hdp|
                hdp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                hdp.time_unix_nano = end_time
                hdp = hdp.dup
                hdp.positive = hdp.positive.dup
                hdp.negative = hdp.negative.dup
                hdp
              end
            end
          end

          def update(amount, attributes, data_points, cardinality_limit)
            hdp = if data_points.key?(attributes)
                    data_points[attributes]
                  elsif data_points.size >= cardinality_limit
                    data_points[OVERFLOW_ATTRIBUTE_SET] || create_new_data_point(OVERFLOW_ATTRIBUTE_SET, data_points)
                  else
                    create_new_data_point(attributes, data_points)
                  end

            update_histogram_data_point(hdp, amount)
            nil
          end

          def aggregation_temporality
            @aggregation_temporality.temporality
          end

          private

          def create_new_data_point(attributes, data_points)
            if @record_min_max
              min = Float::INFINITY
              max = -Float::INFINITY
            end

            data_points[attributes] = ExponentialHistogramDataPoint.new(
              attributes,
              nil,                                                               # :start_time_unix_nano
              0,                                                                 # :time_unix_nano
              0,                                                                 # :count
              0,                                                                 # :sum
              @scale,                                                            # :scale
              @zero_count,                                                       # :zero_count
              ExponentialHistogram::Buckets.new,  # :positive
              ExponentialHistogram::Buckets.new,  # :negative
              0,                                                                 # :flags
              nil,                                                               # :exemplars
              min,                                                               # :min
              max,                                                               # :max
              @zero_threshold # :zero_threshold)
            )
          end

          def update_histogram_data_point(hdp, amount)
            # Start to populate the data point (esp. the buckets)
            if @record_min_max
              hdp.max = amount if amount > hdp.max
              hdp.min = amount if amount < hdp.min
            end

            hdp.sum += amount
            hdp.count += 1

            if amount.abs <= @zero_threshold
              hdp.zero_count += 1
              hdp.scale = 0 if hdp.count == hdp.zero_count # if always getting zero, then there is no point to keep doing the update
              return
            end

            # rescale, map to index, update the buckets here
            buckets = amount.positive? ? hdp.positive : hdp.negative
            amount = -amount if amount.negative?

            bucket_index = @mapping.map_to_index(amount)

            rescaling_needed = false
            low = high = 0

            if buckets.counts == [0] # special case of empty
              buckets.index_start = bucket_index
              buckets.index_end   = bucket_index
              buckets.index_base  = bucket_index

            elsif bucket_index < buckets.index_start && (buckets.index_end - bucket_index) >= @size
              rescaling_needed = true
              low = bucket_index
              high = buckets.index_end

            elsif bucket_index > buckets.index_end && (bucket_index - buckets.index_start) >= @size
              rescaling_needed = true
              low = buckets.index_start
              high = bucket_index
            end

            if rescaling_needed
              scale_change = get_scale_change(low, high)
              downscale(scale_change, hdp.positive, hdp.negative)
              new_scale = @mapping.scale - scale_change
              hdp.scale = new_scale
              @mapping = new_mapping(new_scale)
              bucket_index = @mapping.map_to_index(amount)

              OpenTelemetry.logger.debug "Rescaled with new scale #{new_scale} from #{low} and #{high}; bucket_index is updated to #{bucket_index}"
            end

            # adjust buckets based on the bucket_index
            if bucket_index < buckets.index_start
              span = buckets.index_end - bucket_index
              grow_buckets(span, buckets)
              buckets.index_start = bucket_index
            elsif bucket_index > buckets.index_end
              span = bucket_index - buckets.index_start
              grow_buckets(span, buckets)
              buckets.index_end = bucket_index
            end

            bucket_index -= buckets.index_base
            bucket_index += buckets.counts.size if bucket_index.negative?

            buckets.increment_bucket(bucket_index)
          end

          def grow_buckets(span, buckets)
            return if span < buckets.counts.size

            OpenTelemetry.logger.debug "buckets need to grow to #{span + 1} from #{buckets.counts.size} (max bucket size #{@size})"
            buckets.grow(span + 1, @size)
          end

          def new_mapping(scale)
            scale = validate_scale(scale)
            scale <= 0 ? ExponentialHistogram::ExponentMapping.new(scale) : ExponentialHistogram::LogarithmMapping.new(scale)
          end

          def empty_counts
            @boundaries ? Array.new(@boundaries.size + 1, 0) : nil
          end

          def get_scale_change(low, high)
            # puts "get_scale_change: low: #{low}, high: #{high}, @size: #{@size}"
            # python code also produce 18 with 0,1048575, the high is little bit off
            # just checked, the mapping is also ok, produce the 1048575
            change = 0
            while high - low >= @size
              high >>= 1
              low >>= 1
              change += 1
            end
            change
          end

          def downscale(change, positive, negative)
            return if change <= 0

            positive.downscale(change)
            negative.downscale(change)
          end

          def validate_scale(scale)
            raise ArgumentError, "Scale #{scale} is larger than maximum scale #{MAX_SCALE}" if scale > MAX_SCALE
            raise ArgumentError, "Scale #{scale} is smaller than minimum scale #{MIN_SCALE}" if scale < MIN_SCALE

            scale
          end

          def validate_size(size)
            raise ArgumentError, "Max size #{size} is smaller than minimum size #{MIN_MAX_SIZE}" if size < MIN_MAX_SIZE
            raise ArgumentError, "Max size #{size} is larger than maximum size #{MAX_MAX_SIZE}" if size > MAX_MAX_SIZE

            size
          end
        end
      end
    end
  end
end
