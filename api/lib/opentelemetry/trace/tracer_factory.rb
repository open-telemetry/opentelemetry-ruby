# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # No-op implementation of a tracer factory.
    class TracerFactory
      HTTP_EXTRACTOR = Propagation::HttpTraceContextExtractor.new
      HTTP_INJECTOR = Propagation::HttpTraceContextInjector.new
      RACK_HTTP_EXTRACTOR = Propagation::HttpTraceContextExtractor.new(
        traceparent_header_key: 'HTTP_TRACEPARENT',
        tracestate_header_key: 'HTTP_TRACESTATE'
      )
      RACK_HTTP_INJECTOR = Propagation::HttpTraceContextInjector.new(
        traceparent_header_key: 'HTTP_TRACEPARENT',
        tracestate_header_key: 'HTTP_TRACESTATE'
      )
      BINARY_FORMAT = Propagation::BinaryFormat.new
      private_constant :HTTP_INJECTOR, :HTTP_EXTRACTOR, :RACK_HTTP_INJECTOR,
                       :RACK_HTTP_EXTRACTOR, :BINARY_FORMAT

      # Returns a {Tracer} instance.
      #
      # @param [optional String] name Instrumentation package name
      # @param [optional String] version Instrumentation package version
      #
      # @return [Tracer]
      def tracer(name = nil, version = nil)
        @tracer ||= Tracer.new
      end

      def http_extractor
        HTTP_EXTRACTOR
      end

      def http_injector
        HTTP_INJECTOR
      end

      def rack_http_extractor
        RACK_HTTP_EXTRACTOR
      end

      def rack_http_injector
        RACK_HTTP_INJECTOR
      end

      def binary_format
        BINARY_FORMAT
      end
    end
  end
end
