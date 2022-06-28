# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/metrics/aggregation/histogram'

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        extend self

        SUM = ->(v1, v2) { v1 + v2 }
        EXPLICIT_BUCKET_HISTOGRAM = ExplicitBucketHistogram.new
      end
    end
  end
end
