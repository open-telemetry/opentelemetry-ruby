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

          # Collects and exports the current metrics into #metric_snapshots.
          def pull
            export(collect)
          end

          # Appends the given metrics to #metric_snapshots.
          def export(metrics, timeout: nil)
            @mutex.synchronize do
              @metric_snapshots.concat(Array(metrics))
            end
            SUCCESS
          end

          # Clears #metric_snapshots.
          def reset
            @mutex.synchronize do
              @metric_snapshots.clear
            end
          end

          # No-op: there is nothing to shut down for this exporter.
          def shutdown
            SUCCESS
          end
        end
      end
    end
  end
end
