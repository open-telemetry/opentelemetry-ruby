# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      # Extracts context from carriers in the W3C Trace Context format
      class HttpTraceContextExtractor
        # Returns a new HttpTraceContextExtractor that extracts context using the
        # specified header keys
        #
        # @param [String] traceparent_header_key The traceparent header key used in the carrier
        # @param [String] tracestate_header_key The tracestate header key used in the carrier
        # @return [HttpTraceContextExtractor]
        def initialize(traceparent_header_key:, tracestate_header_key:)
          @text_format = TextFormat.new(traceparent_header_key: traceparent_header_key,
                                        tracestate_header_key: tracestate_header_key)
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
        # @return [Context] Updated context
        def extract(context, carrier, &getter)
          span_context = @text_format.extract(carrier, &getter)
          context.set_value(ContextKeys.span_context_key, span_context)
        end
      end
    end
  end
end
