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

          def initialize
            super
            @metric_snapshots = []
            @mutex = Mutex.new
          end

          def pull
            export(collect)
          end

          def export(metrics)
            @mutex.synchronize do
              metrics.instance_of?(Array) ? @metric_snapshots.concat(metrics) : @metric_snapshots << metrics
            end
            SUCCESS
          end

          def reset
            @mutex.synchronize do
              @metric_snapshots.clear
            end
          end

          def shutdown
            SUCCESS
          end
        end
      end
    end
  end
end
