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
        class InMemoryMetricPullExporter
          attr_reader :metric_snapshots, :metric_store

          def initialize
            @metric_snapshots = []
            @mutex = Mutex.new
            @metric_store = OpenTelemetry::SDK::Metrics::State::MetricStore.new
          end

          def collect
            @metric_store.collect
          end

          def pull
            export(collect)
          end

          def export(metrics)
            @mutex.synchronize do
              return FAILURE if @stopped

              @metric_snapshots << metrics
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
