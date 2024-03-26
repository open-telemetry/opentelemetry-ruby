# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Logs
      # The SDK implementation of OpenTelemetry::Logs::LoggerProvider.
      class LoggerProvider < OpenTelemetry::Logs::LoggerProvider
        attr_reader :resource

        UNEXPECTED_ERROR_MESSAGE = 'unexpected error in ' \
          'OpenTelemetry::SDK::Logs::LoggerProvider#%s'

        private_constant :UNEXPECTED_ERROR_MESSAGE

        # Returns a new LoggerProvider instance.
        #
        # @param [optional Resource] resource The resource to associate with
        #   new LogRecords created by {Logger}s created by this LoggerProvider.
        #
        # @return [OpenTelemetry::SDK::Logs::LoggerProvider]
        def initialize(resource: OpenTelemetry::SDK::Resources::Resource.create)
          @log_record_processors = []
          @mutex = Mutex.new
          @resource = resource
          @stopped = false
        end

        # Returns an {OpenTelemetry::SDK::Logs::Logger} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [OpenTelemetry::SDK::Logs::Logger]
        def logger(name:, version: nil)
          version ||= ''

          if !name.is_a?(String) || name.empty?
            OpenTelemetry.logger.warn('LoggerProvider#logger called with an ' \
              "invalid name. Name provided: #{name.inspect}")
          end

          Logger.new(name, version, self)
        end

        # Adds a new log record processor to this LoggerProvider's
        # log_record_processors.
        #
        # @param [LogRecordProcessor] log_record_processor The
        #   {LogRecordProcessor} to add to this LoggerProvider.
        def add_log_record_processor(log_record_processor)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling LoggerProvider#' \
                'add_log_record_processor after shutdown.')
              return
            end
            @log_record_processors = @log_record_processors.dup.push(log_record_processor)
          end
        end

        # Attempts to stop all the activity for this LoggerProvider. Calls
        # {LogRecordProcessor#shutdown} for all registered {LogRecordProcessor}s.
        #
        # This operation may block until all log records are processed. Must
        # be called before turning off the main application to ensure all data
        # are processed and exported.
        #
        # After this is called all newly created {LogRecord}s will be no-op.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('LoggerProvider#shutdown called multiple times.')
              return Export::FAILURE
            end

            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @log_record_processors.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              break [Export::TIMEOUT] if remaining_timeout&.zero?

              processor.shutdown(timeout: remaining_timeout)
            end

            @stopped = true
            results.max || Export::SUCCESS
          end
        end

        # Immediately export all {LogRecord}s that have not yet been exported
        # for all the registered {LogRecordProcessor}s.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the {LogRecordProcessor}
        # exports the completed {LogRecord}s.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            return Export::SUCCESS if @stopped

            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @log_record_processors.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return Export::TIMEOUT if remaining_timeout&.zero?

              processor.force_flush(timeout: remaining_timeout)
            end

            results.max || Export::SUCCESS
          end
        end
      end
    end
  end
end
