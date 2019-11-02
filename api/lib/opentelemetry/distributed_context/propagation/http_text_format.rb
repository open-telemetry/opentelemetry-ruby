# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module DistributedContext
    module Propagation
      # HTTPTextFormat is a formatter that injects and extracts a value as text into carriers that travel in-band across
      # process boundaries.
      #
      # Encoding is expected to conform to the HTTP Header Field semantics. Values are often encoded as RPC/HTTP request
      # headers.
      #
      # The carrier of propagated data on both the client (injector) and server (extractor) side is usually an http request.
      # Propagation is usually implemented via library-specific request interceptors, where the client-side injects values
      # and the server-side extracts them.
      class HTTPTextFormat
        TRACESTATE_HEADER = 'tracestate'
        FIELDS = [TraceParent::TRACE_PARENT_HEADER, TRACESTATE_HEADER].freeze
        DEFAULT_GETTER = ->(carrier, key) { carrier[key] }
        private_constant(:TRACESTATE_HEADER, :FIELDS, :DEFAULT_GETTER)

        # Return a remote {Trace::SpanContext} extracted from the supplied carrier.
        # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If not passed in the default getter will be
        #   used which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [SpanContext] the span context from the header, or a new one if parsing fails.
        def extract(carrier, &getter)
          getter ||= DEFAULT_GETTER
          header = getter.call(carrier, TraceParent::TRACE_PARENT_HEADER)
          tp = TraceParent.from_string(header)

          tracestate = getter.call(carrier, TRACESTATE_HEADER)

          Trace::SpanContext.new(trace_id: tp.trace_id, span_id: tp.span_id, trace_flags: tp.flags, tracestate: tracestate, remote: true)
        rescue OpenTelemetry::Error
          Trace::SpanContext.new
        end

        # Set the span context on the supplied carrier.
        #
        # @param [SpanContext] context The active {Trace::SpanContext}.
        # @yield [Carrier, String, String] carrier, header key, header value.
        def inject(context, carrier)
          yield carrier, TraceParent::TRACE_PARENT_HEADER, TraceParent.from_context(context).to_s
          yield carrier, TRACESTATE_HEADER, context.tracestate unless context.tracestate.nil?
        end

        def fields
          FIELDS
        end
      end
    end
  end
end
