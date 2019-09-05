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
        # Only spans that are sampled are converted, {TraceFlags#sampled?} must
        # return {true}.
        class SimpleSampledSpansProcessor
          # Returns a new {SimpleSampledSpansProcessor} that converts spans to
          # proto and forwards them to the given {span_exporter}.
          #
          # @param span_exporter the (duck type) SpanExporter to where the
          #   sampled Spans are pushed.
          # @return [SimpleSampledSpansProcessor]
          # @raise ArgumentError if the {span_exporter} is {nil}.
          def initialize(span_exporter)
            raise ArgumentError, 'span_exporter' if span_exporter.nil?

            @span_exporter = span_exporter
          end

          # Called when a {Span} is started, if the {Span#recording_events?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just started.
          def on_start(span)
            # Do nothing.
          end

          # Called when a {Span} is ended, if the {Span#recording_events?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just ended.
          def on_end(span)
            return unless span.context.trace_flags.sampled?

            @span_exporter.export([span.to_span_proto])
          rescue => e # rubocop:disable Style/RescueStandardError
            # TODO: log e
            puts e.to_s
          end

          # Called when {Tracer#shutdown} is called.
          def shutdown
            @span_exporter.shutdown
          end
        end
      end
    end
  end
end
