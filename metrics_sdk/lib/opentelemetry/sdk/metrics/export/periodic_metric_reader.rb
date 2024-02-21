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
          def initialize(interval_millis: 60, timout_millis: 30, exporter: nil)
            super()

            @interval_millis = interval_millis
            @timout_millis = timout_millis
            @exporter = exporter
            @thread = nil

            start_reader
          end

          def start_reader
            if @exporter.nil?
              OpenTelemetry.logger.warn 'Missing exporter in PeriodicMetricReader.'
            elsif !@thread.nil?
              OpenTelemetry.logger.warn 'PeriodicMetricReader is running. Please close it if need to restart.'
            else
              @thread = Thread.new { perodic_collect }
            end
          end

          def perodic_collect
            loop do
              sleep(@interval_millis)
              Timeout.timeout(@timout_millis) { @exporter.export(collect) }
            end
          end

          def close_reader
            @thread.kill
            @thread.join
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'Fail to close PeriodicMetricReader.')
          ensure
            @thread = nil
          end

          # TODO: determine correctness: directly kill the reader without waiting for next metrics collection
          def shutdown(timeout: nil)
            close_reader
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
