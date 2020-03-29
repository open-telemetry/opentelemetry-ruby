# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module CorrelationContext
    module Propagation
      # Extracts correlations from carriers in the W3C Correlation Context format
      class TextExtractor
        include Context::Propagation::DefaultGetter

        # Returns a new TextExtractor that extracts context using the specified
        # header key
        #
        # @param [String] correlation_context_key The correlation context header
        #   key used in the carrier
        # @return [TextExtractor]
        def initialize(correlation_context_key: 'Correlation-Context')
          @correlation_context_key = correlation_context_key
        end

        # Extract remote correlations from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [Context] context The context to be updated with extracted correlations
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] context updated with extracted correlations, or the original context
        #   if extraction fails
        def extract(carrier, context, &getter)
          getter ||= default_getter
          header = getter.call(carrier, @correlation_context_key)

          entries = header.gsub(/\s/, '').split(',')

          correlations = entries.each_with_object({}) do |entry, memo|
            # The ignored variable below holds properties as per the W3C spec.
            # OTel is not using them currently, but they might be used for
            # metadata in the future
            kv, = entry.split(';', 2)
            k, v = kv.split('=').map!(&CGI.method(:unescape))
            memo[k] = v
          end

          context.set_value(ContextKeys.correlation_context_key, correlations)
        rescue StandardError
          context
        end
      end
    end
  end
end
