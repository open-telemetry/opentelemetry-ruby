# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation/context_keys'
require 'opentelemetry/baggage/propagation/text_map_injector'
require 'opentelemetry/baggage/propagation/text_map_extractor'

module OpenTelemetry
  module Baggage
    # The Baggage::Propagation module contains injectors and
    # extractors for sending and receiving baggage over the wire
    module Propagation
      extend self

      BAGGAGE_KEY = 'baggage'
      TEXT_MAP_EXTRACTOR = TextMapExtractor.new
      TEXT_MAP_INJECTOR = TextMapInjector.new
      RACK_EXTRACTOR = TextMapExtractor.new(
        baggage_key: 'HTTP_BAGGAGE'
      )
      RACK_INJECTOR = TextMapInjector.new(
        baggage_key: 'HTTP_BAGGAGE'
      )

      private_constant :BAGGAGE_KEY, :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR,
                       :RACK_INJECTOR, :RACK_EXTRACTOR

      # Returns an extractor that extracts context using the W3C Baggage
      # format
      def text_map_injector
        TEXT_MAP_INJECTOR
      end

      # Returns an injector that injects context using the W3C Baggage
      # format
      def text_map_extractor
        TEXT_MAP_EXTRACTOR
      end

      # Returns an extractor that extracts context using the W3C Baggage
      # format with Rack normalized keys (upcased and prefixed with
      # HTTP_)
      def rack_injector
        RACK_INJECTOR
      end

      # Returns an injector that injects context using the W3C Baggage
      # format with Rack normalized keys (upcased and prefixed with
      # HTTP_)
      def rack_extractor
        RACK_EXTRACTOR
      end
    end
  end
end
