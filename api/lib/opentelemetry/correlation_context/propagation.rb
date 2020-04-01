# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/correlation_context/propagation/context_keys'
require 'opentelemetry/correlation_context/propagation/text_injector'
require 'opentelemetry/correlation_context/propagation/text_extractor'

module OpenTelemetry
  module CorrelationContext
    # The Correlation::Propagation module contains injectors and
    # extractors for sending and receiving correlation context over the wire
    module Propagation
      extend self

      TEXT_EXTRACTOR = TextExtractor.new
      TEXT_INJECTOR = TextInjector.new
      RACK_EXTRACTOR = TextExtractor.new(
        correlation_context_key: 'HTTP_CORRELATION_CONTEXT'
      )
      RACK_INJECTOR = TextInjector.new(
        correlation_context_key: 'HTTP_CORRELATION_CONTEXT'
      )

      private_constant :TEXT_INJECTOR, :TEXT_EXTRACTOR, :RACK_INJECTOR,
                       :RACK_EXTRACTOR

      # Returns an extractor that extracts context using the W3C Correlation
      # Context format
      def text_injector
        TEXT_INJECTOR
      end

      # Returns an injector that injects context using the W3C Correlation
      # Context format
      def text_extractor
        TEXT_EXTRACTOR
      end

      # Returns an extractor that extracts context using the W3C Correlation
      # Context format with Rack normalized keys (upcased and prefixed with
      # HTTP_)
      def rack_injector
        RACK_INJECTOR
      end

      # Returns an injector that injects context using the W3C Correlation
      # Context format with Rack normalized keys (upcased and prefixed with
      # HTTP_)
      def rack_extractor
        RACK_EXTRACTOR
      end
    end
  end
end
