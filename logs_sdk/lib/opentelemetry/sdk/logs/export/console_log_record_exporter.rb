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
          end

          def export(log_records, timeout: nil)
            @mutex.synchronize do
              return FAILURE if @stopped

              Array(log_records).each { |s| pp s }
              SUCCESS
            end
          end

          def force_flush(timeout: nil)
            SUCCESS
          end

          def shutdown(timeout: nil)
            @mutex.synchronize { @stopped = true }
            SUCCESS
          end
        end
      end
    end
  end
end
