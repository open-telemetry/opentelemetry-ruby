# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Propagates baggage using the W3C Baggage format
      class TextMapPropagator
        BAGGAGE_KEY = 'baggage'
        FIELDS = [BAGGAGE_KEY].freeze

        private_constant :BAGGAGE_KEY, :FIELDS

        # Inject in-process baggage into the supplied carrier.
        #
        # @param [Carrier] carrier The mutable carrier to inject baggage into
        # @param [Context] context The context to read baggage from
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   text map setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          baggage = context[ContextKeys.baggage_key]

          return if baggage.nil? || baggage.empty?

          setter.set(carrier, BAGGAGE_KEY, encode(baggage))
          nil
        end

        # Extract remote baggage from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [optional Context] context Context to be updated with the baggage
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   text map getter will be used.
        #
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          header = getter.get(carrier, BAGGAGE_KEY)

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
        rescue StandardError => e
          OpenTelemetry.logger.debug "Error extracting W3C baggage: #{e.message}"
          context
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          FIELDS
        end

        private

        def encode(baggage)
          baggage.inject(+'') do |memo, (k, v)|
            memo << CGI.escape(k.to_s) << '=' << CGI.escape(v.to_s) << ','
          end.chop!
        end
      end
    end
  end
end
