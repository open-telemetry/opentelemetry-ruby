# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      module Export
        # A noop exporter that demonstrates and documents the LogExporter
        # duck type. LogExporter allows different logging services to export
        # emitted logs in their own format.
        #
        # To export data an exporter MUST be registered to the {LogEmitterProvider} using
        # a {SimpleLogProcessor} or a {BatchLogProcessor}.
        class NoopLogExporter
          def initialize
            @stopped = false
          end

          # Called to export emitted {LogData}s.
          #
          # @param [Enumerable<LogData>] spans the list of emitted logs to be exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(logs, timeout: nil)
            return SUCCESS unless @stopped

            FAILURE
          end

          # Called when {LogEmitterProvider#force_flush} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Called when {LogEmitterProvider#shutdown} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          def shutdown(timeout: nil)
            @stopped = true
            SUCCESS
          end
        end
      end
    end
  end
end
