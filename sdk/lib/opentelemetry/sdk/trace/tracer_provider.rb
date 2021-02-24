# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {TracerProvider} is the SDK implementation of {OpenTelemetry::Trace::TracerProvider}.
      class TracerProvider < OpenTelemetry::Trace::TracerProvider
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        attr_accessor :active_trace_config, :id_generator
        attr_reader :active_span_processor, :stopped, :resource
        alias stopped? stopped

        # Returns a new {TracerProvider} instance.
        #
        # @return [TracerProvider]
        def initialize(resource = OpenTelemetry::SDK::Resources::Resource.create)
          @mutex = Mutex.new
          @registry = {}
          @active_span_processor = NoopSpanProcessor.instance
          @active_trace_config = Config::TraceConfig::DEFAULT
          @id_generator = OpenTelemetry::Trace
          @registered_span_processors = []
          @stopped = false
          @resource = resource
        end

        # Returns a {Tracer} instance.
        #
        # @param [optional String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Tracer]
        def tracer(name = nil, version = nil)
          name ||= ''
          version ||= ''
          @mutex.synchronize { @registry[Key.new(name, version)] ||= Tracer.new(name, version, self) }
        end

        # Attempts to stop all the activity for this {TracerProvider}. Calls
        # SpanProcessor#shutdown for all registered SpanProcessors.
        #
        # This operation may block until all the Spans are processed. Must be
        # called before turning off the main application to ensure all data are
        # processed and exported.
        #
        # After this is called all the newly created {Span}s will be no-op.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#shutdown multiple times.')
              return
            end
            @active_span_processor.shutdown(timeout: timeout)
            @stopped = true
          end
        end

        # Immediately export all spans that have not yet been exported for all the
        # registered SpanProcessors.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            return Export::SUCCESS if @stopped

            @active_span_processor.force_flush(timeout: timeout)
          end
        end

        # Adds a new SpanProcessor to this {Tracer}.
        #
        # @param span_processor the new SpanProcessor to be added.
        def add_span_processor(span_processor)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#add_span_processor after shutdown.')
              return
            end
            @registered_span_processors << span_processor
            @active_span_processor = if @registered_span_processors.size == 1
                                       span_processor
                                     else
                                       MultiSpanProcessor.new(@registered_span_processors.dup)
                                     end
          end
        end
      end
    end
  end
end
