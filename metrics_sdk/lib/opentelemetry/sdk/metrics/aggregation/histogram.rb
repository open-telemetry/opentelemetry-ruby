# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        class ExplicitBucketHistogram
          # The Default Value represents the following buckets:
          # (-∞, 0], (0, 5.0], (5.0, 10.0], (10.0, 25.0], (25.0, 50.0],
          # (50.0, 75.0], (75.0, 100.0], (100.0, 250.0], (250.0, 500.0],
          # (500.0, 1000.0], (1000.0, +∞)
          DEFAULT_BOUNDARIES = [0, 5, 10, 25, 50, 75, 100, 250, 500, 1000].freeze
          def initialize(boundaries: DEFAULT_BOUNDARIES, record_min_max: true)
            @boundaries = boundaries
            @record_min_max = record_min_max

          end

          def call(v1, v2)
            # TODO:
          end
        end
      end
    end
  end
end
