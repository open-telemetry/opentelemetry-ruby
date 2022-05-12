# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class InMemoryMetricPullExporter < MetricReader
          PREFERRED_TEMPORALITY = 'delta'

          attr_reader :metric_snapshots

          def initialize
            @metric_snapshots = []
            @mutex = Mutex.new
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

          def preferred_temporality
            PREFERRED_TEMPORALITY
          end
        end
      end
    end
  end
end

