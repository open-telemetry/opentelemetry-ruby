# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        class PeriodicExportingMetricReader < MetricReader
          # exporter - the push exporter where the metrics are sent to.
          # exportIntervalMillis - the time interval in milliseconds between two consecutive exports. The default value is 60000 (milliseconds).
          # exportTimeoutMillis - how long the export can run before it is cancelled. The default value is 30000 (milliseconds).
          def initialize(exporter, aggregation_temporality: nil, export_interval_millis: 60_000, export_timeout_millis: 30_000)
            @exporter = exporter
            @export_interval_millis = export_interval_millis
            @export_timeout_millis = export_timeout_millis
            @aggregation_temporality = aggregation_temporality || exporter.preferred_temporality # || Cumulative

            @thread = Thread.new { work }
          end

          private

          def work
            sleep(3)
            @exporter.export(collect)
          end
        end
      end
    end
  end
end
