# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module CorrelationContext
    module Propagation
      # Extracts correlations from carriers in the W3C Correlation Context format
      class HttpCorrelationContextExtractor
        # @todo we need a common base class
        DEFAULT_GETTER = ->(carrier, key) { carrier[key] }
        private_constant :DEFAULT_GETTER

        # Returns a new HttpCorrelationContextExtractor that extracts context using the
        # specified header key
        #
        # @param [String] correlation_context_header_key The correlation context header
        #   key used in the carrier
        # @return [HttpCorrelationContextExtractor]
        def initialize(correlation_context_key: 'correlationcontext')
          @correlation_context_key = correlation_context_key
        end

        # Extract remote correlations from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Context] context The context to be updated with extracted correlations
        # @param [Carrier] carrier The carrier to get the header from
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] context updated with extracted correlations, or the original context
        #   if extraction fails
        def extract(context, carrier, &getter) # rubocop:disable Metrics/AbcSize
          getter ||= DEFAULT_GETTER
          header = getter.call(carrier, @correlation_context_key)

          entries = header.gsub(/\s/, '').split(',')

          correlations = entries.each_with_object({}) do |entry, memo|
            kv, *props = entry.split(';')
            k, v = kv.split('=').map!(&CGI.method(:unescape))

            # not sure what to do with properties, for now just add append to the value
            memo[k] = props.empty? ? v : v << ';' << props.join(';')
          end

          context.set_value(ContextKeys.span_context_key, correlations)
        end
      end
    end
  end
end
