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
        # extract will return a SpanContext from the supplied carrier
        # invalid headers will result in a new SpanContext
        # @param [Carrier] the carrier to get the header from
        # @yield [Carrier, String] the header key
        # {SpanContext}
        def extract(carrier)
          raise ArgumentError, 'block must be supplied' unless block_given?

          header = yield carrier, TraceParent::TRACE_PARENT_HEADER
          tp = TraceParent.from_string(header)

          SpanContext.new(trace_id: tp.trace_id, span_id: tp.span_id, flags: tp.flags)
        rescue OpenTelemetry::Error
          SpanContext.new
        end

        # inject will set the span context on the supplied carrier
        # @param [Context] the carrier
        # @yield [Carrier, String, String] carrier, header key, header value
        # {SpanContext}
        def inject(context, carrier)
          raise ArgumentError, 'block must be supplied' unless block_given?

          yield carrier, TraceParent::TRACE_PARENT_HEADER, TraceParent.from_context(context).to_s
        end

        def fields
          [TraceParent::TRACE_PARENT_HEADER]
        end
      end
    end
  end
end
