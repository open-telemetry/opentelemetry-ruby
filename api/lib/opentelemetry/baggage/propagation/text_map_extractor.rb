# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Extracts baggage from carriers in the W3C Baggage format
      class TextMapExtractor
        # Returns a new TextMapExtractor that extracts context using the specified
        # getter
        #
        # @param [optional Getter] default_getter The default getter used to read
        #   headers from a carrier during extract. Defaults to a
        #   {OpenTelemetry::Context::Propagation::TextMapGetter} instance.
        # @return [TextMapExtractor]
        def initialize(default_getter = Context::Propagation.text_map_getter)
          @default_getter = default_getter
        end

        # Extract remote baggage from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [Context] context The context to be updated with extracted baggage
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context, getter = nil)
          getter ||= @default_getter
          header = getter.get(carrier, BAGGAGE_KEY)

          entries = header.gsub(/\s/, '').split(',')

          OpenTelemetry.baggage.build(context: context) do |builder|
            entries.each do |entry|
              # Note metadata is currently unused in OpenTelemetry, but is part
              # the W3C spec where it's referred to as properties. We preserve
              # the properties (as-is) so that they can be propagated elsewhere.
              kv, meta = entry.split(';', 2)
              k, v = kv.split('=').map!(&CGI.method(:unescape))

              builder.set_value(k, v, metadata: meta)
            end
          end
        rescue StandardError
          context
        end
      end
    end
  end
end
