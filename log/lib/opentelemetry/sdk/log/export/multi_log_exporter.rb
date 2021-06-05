# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      module Export
        # Implementation of the LogExporter duck type that simply forwards all
        # received logs to a collection of LogExporters.
        #
        # Can be used to export to multiple backends using the same
        # LogProcessor like a {SimpleLogProcessor} or a
        # {BatchLogProcessor}.
        class MultiLogExporter
          def initialize(log_exporters)
            @log_exporters = log_exporters.clone.freeze
          end

          # Called to export emitted {LogData}s.
          #
          # @param [Enumerable<LogData>] spans the list of emitted {LogData}s to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(logs, timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @log_exporters.map do |log_exporter|
              log_exporter.export(logs, timeout: OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time))
            rescue => e # rubocop:disable Style/RescueStandardError
              OpenTelemetry.logger.warn("exception raised by export - #{e}")
              FAILURE
            end
            results.uniq.max || SUCCESS
          end

          # Called when {LogEmitterProvider#force_flush} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @log_exporters.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              processor.force_flush(timeout: remaining_timeout)
            end
            results.uniq.max || SUCCESS
          end

          # Called when {LogEmitterProvider#shutdown} is called, if this exporter is
          # registered to a {LogEmitterProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @log_exporters.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return TIMEOUT if remaining_timeout&.zero?

              processor.shutdown(timeout: remaining_timeout)
            end
            results.uniq.max || SUCCESS
          end
        end
      end
    end
  end
end
