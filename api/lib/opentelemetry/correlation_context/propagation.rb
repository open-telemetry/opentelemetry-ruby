# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/correlation_context/propagation/context_keys'
require 'opentelemetry/correlation_context/propagation/http_injector'
require 'opentelemetry/correlation_context/propagation/http_extractor'

module OpenTelemetry
  module CorrelationContext
    # The Correlation::Propagation module contains injectors and
    # extractors for sending and receiving correlation context over the wire
    module Propagation
      extend self

      HTTP_EXTRACTOR = HttpExtractor.new
      HTTP_INJECTOR = HttpInjector.new
      RACK_HTTP_EXTRACTOR = HttpExtractor.new(
        correlation_context_key: 'HTTP_CORRELATION_CONTEXT'
      )
      RACK_HTTP_INJECTOR = HttpInjector.new(
        correlation_context_key: 'HTTP_CORRELATION_CONTEXT'
      )

      private_constant :HTTP_INJECTOR, :HTTP_EXTRACTOR, :RACK_HTTP_INJECTOR,
                       :RACK_HTTP_EXTRACTOR

      # Returns an extractor that extracts context using the W3C Correlation
      # Context format for HTTP
      def http_injector
        HTTP_INJECTOR
      end

      # Returns an injector that injects context using the W3C Correlation
      # Context format for HTTP
      def http_extractor
        HTTP_EXTRACTOR
      end

      # Returns an extractor that extracts context using the W3C Correlation
      # Context format for HTTP with Rack normalized keys (upcased and
      # prefixed with HTTP_)
      def rack_http_injector
        RACK_HTTP_INJECTOR
      end

      # Returns an injector that injects context using the W3C Correlation
      # Context format for HTTP with Rack normalized keys (upcased and
      # prefixed with HTTP_)
      def rack_http_extractor
        RACK_HTTP_EXTRACTOR
      end
    end
  end
end
