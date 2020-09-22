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
        # @param [Context] parent_context the parent {Context} of the newly
        #  started span.
        def on_start(span, parent_context)
          @span_processors.each { |processor| processor.on_start(span, parent_context) }
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
        #
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush
          @span_processors.map(&:force_flush).uniq.max
        end

        # Called when {TracerProvider#shutdown} is called.
        #
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown
          @span_processors.map(&:shutdown).uniq.max
        end
      end
    end
  end
end
