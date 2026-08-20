# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # The InMemoryMetricPullExporter behaves as a Metric Reader and Exporter.
        # To be used for testing purposes, not production.
        class InMemoryMetricPullExporter < MetricReader
          attr_reader :metric_snapshots

          def initialize(aggregation_cardinality_limit: nil)
            super
            @metric_snapshots = []
            @mutex = Mutex.new
          end

          # Collects and stores the current metrics snapshot.
          def pull
            export(collect)
          end

          # Appends metrics to the in-memory snapshots.
          def export(metrics, timeout: nil)
            @mutex.synchronize do
              @metric_snapshots.concat(Array(metrics))
            end
            SUCCESS
          end

          # Removes all stored metric snapshots.
          def reset
            @mutex.synchronize do
              @metric_snapshots.clear
            end
          end

          # Shuts down the in-memory exporter.
          def shutdown
            SUCCESS
          end
        end
      end
    end
  end
end
