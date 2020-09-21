# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # An implementation of the duck type SpanProcessor that converts the
        # {Span} to {io.opentelemetry.proto.trace.v1.Span} and passes it to the
        # configured exporter.
        #
        # Only spans that are recorded are converted, {OpenTelemetry::Trace::Span#is_recording?} must
        # return true.
        class SimpleSpanProcessor
          # Returns a new {SimpleSpanProcessor} that converts spans to
          # proto and forwards them to the given span_exporter.
          #
          # @param span_exporter the (duck type) SpanExporter to where the
          #   recorded Spans are pushed.
          # @return [SimpleSpanProcessor]
          # @raise ArgumentError if the span_exporter is nil.
          def initialize(span_exporter)
            @span_exporter = span_exporter
          end

          # Called when a {Span} is started, if the {Span#recording?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just started.
          def on_start(span)
            # Do nothing.
          end

          # Called when a {Span} is ended, if the {Span#recording?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just ended.
          def on_finish(span)
            return unless span.context.trace_flags.sampled?

            @span_exporter&.export([span.to_span_data])
          rescue => e # rubocop:disable Style/RescueStandardError
            OpenTelemetry.logger.error("unexpected error in span.on_finish - #{e}")
          end

          # Export all ended spans to the configured `Exporter` that have not yet
          # been exported.
          #
          # This method should only be called in cases where it is absolutely
          # necessary, such as when using some FaaS providers that may suspend
          # the process after an invocation, but before the `Processor` exports
          # the completed spans.
          #
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush
            SUCCESS
          end

          # Called when {TracerProvider#shutdown} is called.
          #
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown
            @span_exporter&.shutdown || SUCCESS
          end
        end
      end
    end
  end
end
