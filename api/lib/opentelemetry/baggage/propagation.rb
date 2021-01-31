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

      private_constant :BAGGAGE_KEY, :TEXT_MAP_INJECTOR, :TEXT_MAP_EXTRACTOR

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
    end
  end
end
