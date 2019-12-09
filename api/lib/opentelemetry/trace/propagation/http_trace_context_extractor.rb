# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      # Extracts context from carriers in the W3C Trace Context format
      class HttpTraceContextExtractor
        DEFAULT_GETTER = ->(carrier, key) { carrier[key] }
        private_constant :DEFAULT_GETTER

        # Returns a new HttpTraceContextExtractor that extracts context using the
        # specified header keys
        #
        # @param [String] traceparent_header_key The traceparent header key used in the carrier
        # @param [String] tracestate_header_key The tracestate header key used in the carrier
        # @return [HttpTraceContextExtractor]
        def initialize(traceparent_header_key:, tracestate_header_key:)
          @traceparent_header_key = traceparent_header_key
          @tracestate_header_key = tracestate_header_key
        end

        # Extract a remote {Trace::SpanContext} from the supplied carrier.
        # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
        #
        # @param [Context] context The context to be updated with extracted context
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] Updated context with span context from the header, or a new one if
        #   parsing fails.
        def extract(context, carrier, &getter)
          getter ||= DEFAULT_GETTER
          header = getter.call(carrier, @traceparent_header_key)
          tp = TraceParent.from_string(header)

          tracestate = getter.call(carrier, @tracestate_header_key)

          span_context = Trace::SpanContext.new(trace_id: tp.trace_id,
                                                span_id: tp.span_id,
                                                trace_flags: tp.flags,
                                                tracestate: tracestate,
                                                remote: true)
          context.set_value(ContextKeys.span_context_key, span_context)
        rescue OpenTelemetry::Error
          context.set_value(ContextKeys.span_context_key, Trace::SpanContext.new)
        end
      end
    end
  end
end
