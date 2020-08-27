# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Injects baggage using the W3C Baggage format
      class TextMapInjector
        include Context::Propagation::DefaultSetter

        # Returns a new TextMapInjector that injects context using the specified
        # header key
        #
        # @param [String] baggage_header_key The baggage header
        #   key used in the carrier
        # @return [TextMapInjector]
        def initialize(baggage_key: 'baggage')
          @baggage_key = baggage_key
        end

        # Inject in-process baggage into the supplied carrier.
        #
        # @param [Carrier] carrier The carrier to inject baggage into
        # @param [Context] context The context to read baggage from
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, inject will yield the carrier
        #   and the header key to the getter.
        # @return [Object] carrier with injected baggage
        def inject(carrier, context, &setter)
          return carrier unless (baggage = context[ContextKeys.baggage_key]) && !baggage.empty?

          setter ||= default_setter
          setter.call(carrier, @baggage_key, encode(baggage))

          carrier
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
