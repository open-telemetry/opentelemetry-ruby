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
        # Returns a new TextMapInjector that injects context using the specified
        # setter
        #
        # @param [optional Setter] default_setter The default setter used to
        #   write context into a carrier during inject. Defaults to a
        #   {TextMapSetter} instance.
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
          return carrier unless (baggage = context[ContextKeys.baggage_key]) && !baggage.empty?

          setter ||= @default_setter
          setter.set(carrier, BAGGAGE_KEY, encode(baggage))

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
