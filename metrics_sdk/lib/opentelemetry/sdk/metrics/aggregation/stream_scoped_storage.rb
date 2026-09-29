# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Builds the nested storage aggregations use to keep per-stream state
        # apart, since a wildcard or regex view shares one aggregation instance
        # across every stream it matches.
        module StreamScopedStorage
          private

          # Streams are keyed by their +data_points+ hash, which is mutable, so
          # the outer hash must compare by identity rather than by value.
          def new_stream_storage
            Hash.new { |h, k| h[k] = {} }.compare_by_identity
          end
        end
      end
    end
  end
end
