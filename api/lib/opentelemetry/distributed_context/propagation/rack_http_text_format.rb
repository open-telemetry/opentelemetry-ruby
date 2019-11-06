# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/distributed_context/propagation/text_format_base'

module OpenTelemetry
  module DistributedContext
    module Propagation
      # The RackHTTPTextFormat is a Rack variant of the HTTPTextFormat formatter that injects and extracts a value as
      # text into carriers using Rack normalized keys that travel in-band across process boundaries.
      #
      # Encoding is expected to conform to the HTTP Header Field semantics. Values are often encoded as RPC/HTTP request
      # headers.
      #
      # The carrier of propagated data on both the client (injector) and server (extractor) side is usually an http request.
      # Propagation is usually implemented via library-specific request interceptors, where the client-side injects values
      # and the server-side extracts them.
      class RackHTTPTextFormat < TextFormatBase
        TRACE_PARENT_HEADER_KEY = 'HTTP_TRACEPARENT'
        TRACE_STATE_HEADER_KEY = 'HTTP_TRACESTATE'
        FIELDS = [TRACE_PARENT_HEADER_KEY, TRACE_STATE_HEADER_KEY].freeze
      end
    end
  end
end
