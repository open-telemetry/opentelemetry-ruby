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
          def initialize(aggregation_cardinality_limit: nil)
            super
            @stopped = false
          end

          # Collects and exports the current metrics to the console.
          def pull
            export(collect)
          end

          # Writes the supplied metrics to the console unless shut down.
          def export(metrics, timeout: nil)
            return FAILURE if @stopped

            Array(metrics).each { |metric| pp metric }

            SUCCESS
          end

          # @return [Integer] success because console export needs no flushing.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Stops this exporter from accepting further exports.
          def shutdown(timeout: nil)
            @stopped = true
            SUCCESS
          end
        end
      end
    end
  end
end
