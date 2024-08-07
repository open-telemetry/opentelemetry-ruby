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
          # Returns a new instance of the {PeriodicMetricReader}.
          #
          # @param [Integer] export_interval_millis the maximum interval time.
          #   Defaults to the value of the OTEL_METRIC_EXPORT_INTERVAL environment
          #   variable, if set, or 60_000.
          # @param [Integer] export_timeout_millis the maximum export timeout.
          #   Defaults to the value of the OTEL_METRIC_EXPORT_TIMEOUT environment
          #   variable, if set, or 30_000.
          # @param [MetricReader] exporter the (duck type) MetricReader to where the
          #   recorded metrics are pushed after certain interval.
          #
          # @return a new instance of the {PeriodicMetricReader}.
          def initialize(export_interval_millis: Float(ENV.fetch('OTEL_METRIC_EXPORT_INTERVAL', 60_000)),
                         export_timeout_millis: Float(ENV.fetch('OTEL_METRIC_EXPORT_TIMEOUT', 30_000)),
                         exporter: nil)
            super()

            @export_interval = export_interval_millis / 1000.0
            @export_timeout = export_timeout_millis / 1000.0
            @exporter = exporter
            @thread   = nil
            @continue = false
            @mutex = Mutex.new
            @export_mutex = Mutex.new

            start
          end

          def shutdown(timeout: nil)
            thread = lock do
              @continue = false # force termination in next iteration
              @thread
            end
            thread&.join(@export_interval)
            @exporter.force_flush if @exporter.respond_to?(:force_flush)
            @exporter.shutdown
            Export::SUCCESS
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'Fail to shutdown PeriodicMetricReader.')
            Export::FAILURE
          end

          def force_flush(timeout: nil)
            export(timeout: timeout)
            Export::SUCCESS
          rescue StandardError
            Export::FAILURE
          end

          private

          def start
            @continue = true
            if @exporter.nil?
              OpenTelemetry.logger.warn 'Missing exporter in PeriodicMetricReader.'
            elsif @thread&.alive?
              OpenTelemetry.logger.warn 'PeriodicMetricReader is still running. Please shutdown it if it needs to restart.'
            else
              @thread = Thread.new do
                while @continue
                  sleep(@export_interval)
                  begin
                    Timeout.timeout(@export_timeout) do
                      export(timeout: @export_timeout)
                    end
                  rescue Timeout::Error => e
                    OpenTelemetry.handle_error(exception: e, message: 'PeriodicMetricReader timeout.')
                  end
                end
              end
            end
          end

          def export(timeout: nil)
            @export_mutex.synchronize do
              collected_metrics = collect
              @exporter.export(collected_metrics, timeout: timeout || @export_timeout) unless collected_metrics.empty?
            end
          end

          def lock(&block)
            @mutex.synchronize(&block)
          end
        end
      end
    end
  end
end
