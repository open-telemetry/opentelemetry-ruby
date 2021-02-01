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
          # Returns a new TextMapExtractor that extracts context using the
          # specified getter
          #
          # @param [optional Getter] default_getter The default getter used to read
          #   headers from a carrier during extract. Defaults to a +TextMapGetter+
          #   instance.
          # @return [TextMapExtractor]
          def initialize(default_getter = Context::Propagation.text_map_getter)
            @default_getter = default_getter
          end

          # Extract a remote {Trace::SpanContext} from the supplied carrier.
          # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
          #
          # @param [Carrier] carrier The carrier to get the header from.
          # @param [Context] context The context to be updated with extracted context
          # @param [optional Getter] getter If the optional getter is provided, it
          #   will be used to read the header from the carrier, otherwise the default
          #   getter will be used.
          # @return [Context] Updated context with span context from the header, or the original
          #   context if parsing fails.
          def extract(carrier, context, getter = nil)
            getter ||= @default_getter
            tp = TraceParent.from_string(getter.get(carrier, TRACEPARENT_KEY))
            tracestate = Tracestate.from_string(getter.get(carrier, TRACESTATE_KEY))

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
