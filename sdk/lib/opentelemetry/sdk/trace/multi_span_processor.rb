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
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          if timeout.nil?
            @span_processors.map(&:force_flush).uniq.max
          else
            start_time = Time.now
            @span_processors.map do |processor|
              remaining_timeout = timeout - (Time.now - start_time)
              return Export::TIMEOUT unless remaining_timeout.positive?

              processor.force_flush(timeout: timeout)
            end.uniq.max
          end
        end

        # Called when {TracerProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds. 
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          if timeout.nil?
            @span_processors.map(&:shutdown).uniq.max
          else
            start_time = Time.now
            @span_processors.map do |processor|
              remaining_timeout = timeout - (Time.now - start_time)
              return Export::TIMEOUT unless remaining_timeout.positive?

              processor.shutdown(timeout: timeout)
            end.uniq.max
          end
        end
      end
    end
  end
end
