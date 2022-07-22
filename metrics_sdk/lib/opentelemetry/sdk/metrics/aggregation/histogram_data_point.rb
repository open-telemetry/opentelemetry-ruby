# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        HistogramDataPoint = Struct.new(:start_time_unix_nano, # (Optional)
                                        :time_unix_nano,
                                        :count, # count is the number of values in the population. Must be non-negative.
                                        :sum, # sum of the values in the population. If count is zero then this field then this field must be zero
                                        :bucket_counts, # optional field contains the count values of histogram for each bucket.
                                        :explicit_bounds, # specifies buckets with explicitly defined bounds for values.
                                        :exemplars, # (Optional) List of exemplars collected from measurements that were used to form the data point
                                        :min, # (Optional) min is the minimum value over (start_time, end_time].
                                        :max, # (Optional) max is the maximum value over (start_time, end_time].
                                        :attributes)
      end
    end
  end
end
