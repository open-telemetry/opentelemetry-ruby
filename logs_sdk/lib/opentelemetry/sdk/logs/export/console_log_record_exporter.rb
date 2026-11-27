# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      module Export
        # Outputs {LogRecordData} to the console. Calls to export and shutdown are thread-safe.
        #
        # This exporter is intended for debugging and learning purposes. It is not recommended for production use. The output format is not standardized and can change at any time.
        class ConsoleLogRecordExporter
          def initialize
            @stopped = false
            @mutex = Mutex.new
            @condition = ConditionVariable.new
            @active_exports = 0
          end

          # Exports the provided log records to the console.
          def export(log_records, timeout: nil)
            accepted = @mutex.synchronize do
              next false if @stopped

              @active_exports += 1
              true
            end
            return FAILURE unless accepted

            Array(log_records).each { |s| pp s }
            SUCCESS
          ensure
            if accepted
              @mutex.synchronize do
                @active_exports -= 1
                @condition.broadcast if @active_exports.zero?
              end
            end
          end

          # Flushes any pending log records.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Stops the exporter after any in-flight export has completed.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, TIMEOUT if the deadline elapsed.
          def shutdown(timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp

            @mutex.synchronize do
              @stopped = true
              while @active_exports.positive?
                remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
                return TIMEOUT if remaining_timeout&.zero?

                @condition.wait(@mutex, remaining_timeout)
              end
            end

            SUCCESS
          end
        end
      end
    end
  end
end
