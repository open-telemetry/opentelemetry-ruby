# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Extracts baggage from carriers in the W3C Baggage format
      class TextMapExtractor
        include Context::Propagation::DefaultGetter

        # Returns a new TextMapExtractor that extracts context using the specified
        # header key
        #
        # @param [String] baggage_key The baggage header
        #   key used in the carrier
        # @return [TextMapExtractor]
        def initialize(baggage_key: 'Baggage')
          @baggage_key = baggage_key
        end

        # Extract remote baggage from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [Context] context The context to be updated with extracted baggage
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context, &getter)
          getter ||= default_getter
          header = getter.call(carrier, @baggage_key)

          entries = header.gsub(/\s/, '').split(',')

          baggage = entries.each_with_object({}) do |entry, memo|
            # The ignored variable below holds properties as per the W3C spec.
            # OTel is not using them currently, but they might be used for
            # metadata in the future
            kv, = entry.split(';', 2)
            k, v = kv.split('=').map!(&CGI.method(:unescape))
            memo[k] = v
          end

          context.set_value(ContextKeys.baggage_key, baggage)
        rescue StandardError
          context
        end
      end
    end
  end
end
