# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'pp'

module OpenTelemetry
  module SDK
    module Log
      module Export
        # Outputs {LogData} to the console.
        #
        # Potentially useful for exploratory purposes.
        class ConsoleLogExporter
          def initialize
            @stopped = false
          end

          def export(logs, timeout: nil)
            return FAILURE if @stopped

            Array(logs).each { |s| pp s }

            SUCCESS
          end

          def force_flush(timeout: nil)
            SUCCESS
          end

          def shutdown(timeout: nil)
            @stopped = true
            SUCCESS
          end
        end
      end
    end
  end
end
