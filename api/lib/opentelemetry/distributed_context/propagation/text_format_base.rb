# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module DistributedContext
    module Propagation
      # TextFormatBase is an abstract class that provides common functionality to inject and extract
      # values into carriers that travel in-band across process boundaries. At a minmum subclasses
      # need to provide the following constants:
      #   - TRACE_PARENT_HEADER_KEY: the key to associate with the trace parent entry in a carrier
      #   - TRACE_STATE_HEADER_KEY: the to associated with the trace state entry in a carrier
      #   - FIELDS: an array containing the keys that are referenced by the formatter
      #
      # Encoding is expected to conform to the HTTP Header Field semantics. Values are often encoded as RPC/HTTP request
      # headers.
      #
      # The carrier of propagated data on both the client (injector) and server (extractor) side is usually an http request.
      # Propagation is usually implemented via library-specific request interceptors, where the client-side injects values
      # and the server-side extracts them.
      class TextFormatBase
        DEFAULT_GETTER = ->(carrier, key) { carrier[key] }
        DEFAULT_SETTER = ->(carrier, key, value) { carrier[key] = value }
        private_constant(:DEFAULT_GETTER, :DEFAULT_SETTER)

        # Return a remote {Trace::SpanContext} extracted from the supplied carrier. Expects the
        # the supplied carrier to have keys in rack normalized format (HTTP_#{UPPERCASE_KEY}).
        # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [SpanContext] the span context from the header, or a new one if parsing fails.
        def extract(carrier, &getter)
          getter ||= DEFAULT_GETTER
          header = getter.call(carrier, trace_parent_header_key)
          tp = TraceParent.from_string(header)

          tracestate = getter.call(carrier, trace_state_header_key)

          Trace::SpanContext.new(trace_id: tp.trace_id, span_id: tp.span_id, trace_flags: tp.flags, tracestate: tracestate, remote: true)
        rescue OpenTelemetry::Error
          Trace::SpanContext.new
        end

        # Set the span context on the supplied carrier.
        #
        # @param [SpanContext] context The active {Trace::SpanContext}.
        # @param [optional Callable] setter An optional callable that takes a carrier and a key and
        #   a value and assigns the key-value pair in the carrier. If omitted the default setter
        #   will be used which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String, String] if an optional setter is provided, inject will yield
        #   carrier, header key, header value to the setter.
        def inject(context, carrier, &setter)
          setter ||= DEFAULT_SETTER
          setter.call(carrier, trace_parent_header_key, TraceParent.from_context(context).to_s)
          setter.call(carrier, trace_state_header_key, context.tracestate) unless context.tracestate.nil?
        end

        def fields
          self.class::FIELDS
        end

        private

        def trace_parent_header_key
          self.class::TRACE_PARENT_HEADER_KEY
        end

        def trace_state_header_key
          self.class::TRACE_STATE_HEADER_KEY
        end
      end
    end
  end
end
