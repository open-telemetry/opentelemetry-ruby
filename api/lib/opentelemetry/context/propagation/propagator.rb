# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A propagator composes an extractor and injector into a single interface
      # exposing inject and extract methods
      class Propagator
        # Returns a Propagator that delegates inject and extract to the provided
        # injector and extractor
        #
        # @param [#inject] injector
        # @param [#extract] extractor
        def initialize(injector, extractor)
          @injector = injector
          @extractor = extractor
        end

        # Returns a carrier with the provided context injected according the
        # underlying injector. Returns the carrier and logs a warning if
        # injection fails.
        #
        # @param [Object] carrier A carrier to inject context into
        #   context into
        # @param [optional Context] context Context to be injected into carrier. Defaults
        #   to +Context.current+
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        #
        # @return [Object] carrier
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          @injector.inject(carrier, context, setter)
        rescue => e # rubocop:disable Style/RescueStandardError
          OpenTelemetry.logger.warn "Error in Propagator#inject #{e.message}"
          carrier
        end

        # Extracts and returns context from a carrier. Returns the provided
        # context and logs a warning if an error if extraction fails.
        #
        # @param [Object] carrier The carrier to extract context from
        # @param [optional Context] context Context to be updated with the state
        #   extracted from the carrier. Defaults to +Context.current+
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        #
        # @return [Context] a new context updated with state extracted from the
        #   carrier
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          @extractor.extract(carrier, context, getter)
        rescue => e # rubocop:disable Style/RescueStandardError
          OpenTelemetry.logger.warn "Error in Propagator#extract #{e.message}"
          context
        end
      end
    end
  end
end
