# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer
        # Returns a new {Tracer} instance.
        #
        # @return [Tracer]
        def initialize
          @active_span_processor = NoopSpanProcessor.instance
          @registered_span_processors = []
          @mutex = Mutex.new
          @stopped = false
        end

        # Attempts to stop all the activity for this {Tracer}. Calls
        # SpanProcessor#shutdown for all registered SpanProcessors.
        #
        # This operation may block until all the Spans are processed. Must be
        # called before turning off the main application to ensure all data are
        # processed and exported.
        #
        # After this is called all the newly created {Span}s will be no-op.
        def shutdown
          @mutex.synchronize do
            if @stopped
              # TODO: log instead of puts
              puts 'WARNING: calling Tracer#shutdown multiple times.'
            else
              @active_span_processor.shutdown
              @stopped = true
            end
          end
        end

        # Adds a new SpanProcessor to this {Tracer}.
        #
        # Any registered processor causes overhead, consider to use an
        # async/batch processor especially for span exporting, and export to
        # multiple backends using the
        # {io.opentelemetry.sdk.trace.export.MultiSpanExporter}.
        #
        # @param span_processor the new SpanProcessor to be added.
        def add_span_processor(span_processor)
          @mutex.synchronize do
            @registered_span_processors << span_processor
            @active_span_processor = MultiSpanProcessor.new(registered_span_processors)
          end
        end
      end
    end
  end
end
