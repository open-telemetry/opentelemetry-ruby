# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # Outputs {MetricData} to the console
        #
        # Potentially useful for exploratory purposes.
        class ConsoleMetricPullExporter < MetricReader
          # Collects and exports the current metrics to the console.
          def pull
            export(collect)
          end

          # Prints each collected metric to stdout.
          def export(metrics, timeout: nil)
            return FAILURE if @stopped

            Array(metrics).each { |metric| pp metric }

            SUCCESS
          end

          # No-op: there is nothing to flush for this exporter.
          def force_flush(timeout: nil)
            SUCCESS
          end
        end
      end
    end
  end
end
