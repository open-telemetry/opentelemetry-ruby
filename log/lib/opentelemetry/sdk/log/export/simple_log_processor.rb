# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      module Export
        # An implementation of the duck type LogProcessor that converts the
        # {Log} to {LogData} and passes it to the configured exporter.
        #
        # Typically, the SimpleLogProcessor will be most suitable for use in testing;
        # it should be used with caution in production. It may be appropriate for
        # production use in scenarios where creating multiple threads is not desirable
        # as well as scenarios where different custom attributes should be added to
        # individual logs based on code scopes.
        class SimpleLogProcessor
          # Returns a new {SimpleLogProcessor} that converts logs for export
          # and forwards them to the given span_exporter.
          #
          # @param log_exporter the (duck type) LogExporter to where the
          #   emitted logs are pushed.
          # @return [SimpleLogProcessor]
          # @raise ArgumentError if the span_exporter is nil.
          def initialize(log_exporter)
            raise ArgumentError, "exporter #{log_exporter.inspect} does not appear to be a valid exporter" unless Common::Utilities.valid_exporter?(log_exporter)

            @log_exporter = log_exporter
          end

          # Called when a {LogRecord} is emitted.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [LogData] log_data the {LogData} that was emitted.
          def on_emit(log_data)
            @log_exporter&.export([log_data])
          rescue => e # rubocop:disable Style/RescueStandardError
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error in on_emit')
          end

          # Export all emitted logs to the configured `Exporter` that have not yet
          # been exported, then call {Exporter#force_flush}.
          #
          # This method should only be called in cases where it is absolutely
          # necessary, such as when using some FaaS providers that may suspend
          # the process after an invocation, but before the `Processor` exports
          # the emitted logs.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            @log_exporter&.force_flush(timeout: timeout) || SUCCESS
          end

          # Called when {LogEmitterProvider#shutdown} is called.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            @log_exporter&.shutdown(timeout: timeout) || SUCCESS
          end
        end
      end
    end
  end
end
