# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # Extracts context from carriers in the W3C Trace Context format
        class TextMapExtractor
          include Context::Propagation::DefaultGetter

          # Returns a new TextMapExtractor that extracts context using the
          # specified header keys
          #
          # @param [String] traceparent_key The traceparent header key used in the carrier
          # @param [String] tracestate_key The tracestate header key used in the carrier
          # @return [TextMapExtractor]
          def initialize(traceparent_key: 'traceparent',
                         tracestate_key: 'tracestate')
            @traceparent_key = traceparent_key
            @tracestate_key = tracestate_key
          end

          # Extract a remote {Trace::SpanContext} from the supplied carrier.
          # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
          #
          # @param [Carrier] carrier The carrier to get the header from.
          # @param [Context] context The context to be updated with extracted context
          # @param [optional Callable] getter An optional callable that takes a carrier and a key and
          #   returns the value associated with the key. If omitted the default getter will be used
          #   which expects the carrier to respond to [] and []=.
          # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
          #   and the header key to the getter.
          # @return [Context] Updated context with span context from the header, or the original
          #   context if parsing fails.
          def extract(carrier, context, &getter)
            getter ||= default_getter
            tp = TraceParent.from_string(getter.call(carrier, @traceparent_key))
            tracestate = Tracestate.from_string(getter.call(carrier, @tracestate_key))

            span_context = Trace::SpanContext.new(trace_id: tp.trace_id,
                                                  span_id: tp.span_id,
                                                  trace_flags: tp.flags,
                                                  tracestate: tracestate,
                                                  remote: true)
            span = Trace::Span.new(span_context: span_context)
            OpenTelemetry::Trace.context_with_span(span)
          rescue OpenTelemetry::Error
            context
          end
        end
      end
    end
  end
end
