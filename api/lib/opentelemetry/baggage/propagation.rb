# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation/context_keys'
require 'opentelemetry/baggage/propagation/text_map_injector'
require 'opentelemetry/baggage/propagation/text_map_extractor'

module OpenTelemetry
  module Baggage
    # The Correlation::Propagation module contains injectors and
    # extractors for sending and receiving correlation context over the wire
    module Propagation
      extend self

      TEXT_MAP_EXTRACTOR = TextMapExtractor.new
      TEXT_MAP_INJECTOR = TextMapInjector.new
      RACK_EXTRACTOR = TextMapExtractor.new(
        baggage_key: 'HTTP_OTCORRELATIONS'
      )
      RACK_INJECTOR = TextMapInjector.new(
        baggage_key: 'HTTP_OTCORRELATIONS'
      )

      private_constant :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR, :RACK_INJECTOR,
                       :RACK_EXTRACTOR

      # Returns an extractor that extracts context using the W3C Correlation
      # Context format
      def text_map_injector
        TEXT_MAP_INJECTOR
      end

      # Returns an injector that injects context using the W3C Correlation
      # Context format
      def text_map_extractor
        TEXT_MAP_EXTRACTOR
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
