# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'singleton'

module OpenTelemetry
  module SDK
    module Log
      # NoopLogProcessor is a singleton implementation of the duck type
      # LogProcessor that provides synchronous no-op hooks for when a
      # {LogRecord} is emitted.
      class NoopLogProcessor
        include Singleton

        # Called when a {LogRecord} is emitted from a {LogEmitter}.
        #
        # This method is called synchronously on the execution
        # thread, should not throw or block the execution thread.
        #
        # @param [LogData]
        def on_emit(log_data); end

        # Export all log records to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the emitted logs.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          Export::SUCCESS
        end

        # Called when {LogEmitterProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          Export::SUCCESS
        end
      end
    end
  end
end
