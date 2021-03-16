# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Injects baggage using the W3C Baggage format
      class TextMapInjector
        # Maximums according to W3C Baggage spec
        MAX_ENTRIES = 180
        MAX_ENTRY_LENGTH = 4096
        MAX_TOTAL_LENGTH = 8192
        private_constant :MAX_ENTRIES, :MAX_ENTRY_LENGTH, :MAX_TOTAL_LENGTH

        # Returns a new TextMapInjector that injects context using the specified
        # setter
        #
        # @param [optional Setter] default_setter The default setter used to
        #   write context into a carrier during inject. Defaults to a
        #   {OpenTelemetry::Context::Propagation::TextMapSetter} instance.
        # @return [TextMapInjector]
        def initialize(default_setter = Context::Propagation.text_map_setter)
          @default_setter = default_setter
        end

        # Inject in-process baggage into the supplied carrier.
        #
        # @param [Carrier] carrier The carrier to inject baggage into
        # @param [Context] context The context to read baggage from
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        # @return [Object] carrier with injected baggage
        def inject(carrier, context, setter = nil)
          return carrier unless (baggage = OpenTelemetry.baggage.raw_entries(context: context)) && !baggage.empty?

          setter ||= @default_setter
          encoded_baggage = encode(baggage)
          setter.set(carrier, BAGGAGE_KEY, encoded_baggage) unless encoded_baggage&.empty?
          carrier
        end

        private

        def encode(baggage)
          result = +''
          encoded_count = 0
          baggage.each_pair do |key, entry|
            break unless encoded_count < MAX_ENTRIES

            encoded_entry = encode_value(key, entry)
            next unless encoded_entry.size <= MAX_ENTRY_LENGTH &&
                        encoded_entry.size + result.size <= MAX_TOTAL_LENGTH

            result << encoded_entry << ','
            encoded_count += 1
          end
          result.chop!
        end

        def encode_value(key, entry)
          result = +"#{CGI.escape(key.to_s)}=#{CGI.escape(entry.value.to_s)}"
          # We preserve metadata recieved on extract and assume it's already formatted
          # for transport. It's sent as-is without further processing.
          result << ";#{entry.metadata}" if entry.metadata
          result
        end
      end
    end
  end
end
