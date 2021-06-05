# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Log
      # Provides a way to construct {LogEmitter}s for use by SDK clients.
      class LogEmitterProvider
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        attr_reader :active_log_processor, :stopped, :resource
        alias stopped? stopped

        # Returns a new {LogEmitterProvider} instance.
        #
        # @return [LogEmitterProvider]
        def initialize(resource = OpenTelemetry::SDK::Resources::Resource.create)
          @mutex = Mutex.new
          @registry = {}
          @active_log_processor = NoopLogProcessor.instance
          @registered_log_processors = []
          @stopped = false
          @resource = resource
        end

        # Returns a {LogEmitter} instance.
        #
        # @param [optional String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Tracer]
        def log_emitter(name = nil, version = nil)
          name ||= ''
          version ||= ''
          @mutex.synchronize { @registry[Key.new(name, version)] ||= LogEmitter.new(name, version, self) }
        end

        # Attempts to stop all the activity for this {LogEmitter}. Calls
        # LogProcessor#shutdown for all registered LogProcessors.
        #
        # This operation may block until all the Logs are processed. Must be
        # called before turning off the main application to ensure all data are
        # processed and exported.
        #
        # After this is called all the newly created {Logs}s will be no-op.
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling LogEmitter#shutdown multiple times.')
              return
            end
            @active_log_processor.shutdown(timeout: timeout)
            @stopped = true
          end
        end

        # Immediately export all logs that have not yet been exported for all the
        # registered LogProcessors.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed logs.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            return Export::SUCCESS if @stopped

            @active_log_processor.force_flush(timeout: timeout)
          end
        end

        # Adds a new LogProcessor to this {LogEmitter}.
        #
        # @param log_processor the new LogProcessor to be added.
        def add_log_processor(log_processor)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling LogEmitter#add_log_processor after shutdown.')
              return
            end
            @registered_log_processors << log_processor
            @active_log_processor = if @registered_log_processors.size == 1
                                       log_processor
                                     else
                                       MultiLogProcessor.new(@registered_log_processors.dup)
                                     end
          end
        end
      end
    end
  end
end
