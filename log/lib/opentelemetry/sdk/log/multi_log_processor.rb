# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      # Implementation of the LogProcessor duck type that simply forwards all
      # received events to a list of LogProcessors.
      class MultiLogProcessor
        # Creates a new {MultiLogProcessor}.
        #
        # @param [Enumerable<LogProcessor>] log_processors a collection of
        #   LogProcessors.
        # @return [MultiLogProcessor]
        def initialize(log_processors)
          @log_processors = log_processors.to_a.freeze
        end

        # Called when a {LogRecord} is emitted from a {LogEmitter}.
        #
        # This method is called synchronously on the execution
        # thread, should not throw or block the execution thread.
        #
        # @param [LogData]
        def on_emit(log_data)
          @log_processors.each { |processor| processor.on_emit(log_data) }
        end

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
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          results = @log_processors.map do |processor|
            remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
            return Export::TIMEOUT if remaining_timeout&.zero?

            processor.force_flush(timeout: remaining_timeout)
          end
          results.uniq.max
        end

        # Called when {LogEmitterProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          results = @log_processors.map do |processor|
            remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
            return Export::TIMEOUT if remaining_timeout&.zero?

            processor.shutdown(timeout: remaining_timeout)
          end
          results.uniq.max
        end
      end
    end
  end
end
