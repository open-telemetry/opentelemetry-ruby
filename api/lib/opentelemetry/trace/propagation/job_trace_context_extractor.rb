# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      # Extracts context from carriers in the W3C Trace Context format
      class JobTraceContextExtractor
        include Context::Propagation::DefaultGetter

        # Returns a new JobTraceContextExtractor that extracts context using the
        # specified header keys
        #
        # @param [String] traceparent_key The traceparent header key used in the carrier
        # @param [String] tracestate_key The tracestate header key used in the carrier
        # @return [JobTraceContextExtractor]
        def initialize(traceparent_key: 'traceparent',
                       tracestate_key: 'tracestate')
          @traceparent_key = traceparent_key
          @tracestate_key = tracestate_key
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
        # @return [Context] Updated context with span context from the header, or the original
        #   context if parsing fails.
        def extract(context, carrier, &getter)
          getter ||= default_getter
          header = getter.call(carrier, @traceparent_key)
          tp = TraceParent.from_string(header)

          tracestate = getter.call(carrier, @tracestate_key)

          span_context = Trace::SpanContext.new(trace_id: tp.trace_id,
                                                span_id: tp.span_id,
                                                trace_flags: tp.flags,
                                                tracestate: tracestate,
                                                remote: true)
          context.set_value(ContextKeys.extracted_span_context_key, span_context)
        rescue OpenTelemetry::Error
          context
        end
      end
    end
  end
end
