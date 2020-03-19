# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # Implementation of the SpanProcessor duck type that simply forwards all
      # received events to a list of SpanProcessors.
      class MultiSpanProcessor
        # Creates a new {MultiSpanProcessor}.
        #
        # @param [Enumerable<SpanProcessor>] span_processors a collection of
        #   SpanProcessors.
        # @return [MultiSpanProcessor]
        def initialize(span_processors)
          @span_processors = span_processors.to_a.freeze
        end

        # Called when a {Span} is started, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        def on_start(span)
          @span_processors.each { |processor| processor.on_start(span) }
        end

        # Called when a {Span} is ended, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span)
          @span_processors.each { |processor| processor.on_finish(span) }
        end

        # Export all ended spans to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        def force_flush
          @span_processors.each(&:force_flush)
        end

        # Called when {TracerProvider#shutdown} is called.
        def shutdown
          @span_processors.each(&:shutdown)
        end
      end
    end
  end
end
