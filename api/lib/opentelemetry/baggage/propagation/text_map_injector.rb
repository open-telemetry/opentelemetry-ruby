# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Injects correlation context using the W3C Correlation Context format
      class TextMapInjector
        include Context::Propagation::DefaultSetter

        # Returns a new TextMapInjector that injects context using the specified
        # header key
        #
        # @param [String] baggage_header_key The correlation context header
        #   key used in the carrier
        # @return [TextMapInjector]
        def initialize(baggage_key: 'Baggage')
          @baggage_key = baggage_key
        end

        # Inject in-process correlations into the supplied carrier.
        #
        # @param [Carrier] carrier The carrier to inject correlations into
        # @param [Context] context The context to read correlations from
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, inject will yield the carrier
        #   and the header key to the getter.
        # @return [Object] carrier with injected correlations
        def inject(carrier, context, &setter)
          return carrier unless (correlations = context[ContextKeys.baggage_key]) && !correlations.empty?

          setter ||= default_setter
          setter.call(carrier, @baggage_key, encode(correlations))

          carrier
        end

        private

        def encode(correlations)
          correlations.inject(+'') do |memo, (k, v)|
            memo << CGI.escape(k.to_s) << '=' << CGI.escape(v.to_s) << ','
          end.chop!
        end
      end
    end
  end
end
