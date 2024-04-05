# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Export
        # PeriodicMetricReader provides a minimal example implementation.
        class PeriodicMetricReader < MetricReader
          def initialize(interval_millis: 60, timeout_millis: 30, exporter: nil)
            super()

            @interval_millis = interval_millis
            @timout_millis = timout_millis
            @exporter = exporter
            @thread   = nil
            @continue = false

            start
          end

          def start
            @continue = true
            if @exporter.nil?
              OpenTelemetry.logger.warn 'Missing exporter in PeriodicMetricReader.'
            elsif @thread&.alive?
              OpenTelemetry.logger.warn 'PeriodicMetricReader is still running. Please close it if it needs to restart.'
            else
              @thread = Thread.new do
                while @continue
                  sleep(@interval_millis)
                  begin
                    Timeout.timeout(@timout_millis) { @exporter.export(collect) }
                  rescue Timeout::Error => e
                    OpenTelemetry.handle_error(exception: e, message: 'PeriodicMetricReader timeout.')
                  end
                end
              end
            end
          end

          def close
            @continue = false   # force termination in next iteration
            @thread.join(5)     # wait 5 seconds for collecting and exporting
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'Fail to close PeriodicMetricReader.')
          end

          # TODO: determine correctness: directly kill the reader without waiting for next metrics collection
          def shutdown(timeout: nil)
            close
            @exporter.shutdown
            Export::SUCCESS
          rescue StandardError
            Export::FAILURE
          end

          def force_flush(timeout: nil)
            @exporter.export(collect)
            Export::SUCCESS
          rescue StandardError
            Export::FAILURE
          end
        end
      end
    end
  end
end
