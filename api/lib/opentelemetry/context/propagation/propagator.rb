# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
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
        # @param [optional Callable] setter An optional callable that takes a carrier, a key and
        #   a value and assigns the key-value pair in the carrier. If omitted the default setter
        #   will be used which expects the carrier to respond to [] and []=.
        #
        # @return [Object] carrier
        def inject(carrier, context = Context.current, &setter)
          @injector.inject(carrier, context, &setter)
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
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        #
        # @return [Context] a new context updated with state extracted from the
        #   carrier
        def extract(carrier, context = Context.current, &getter)
          @extractor.extract(carrier, context, &getter)
        rescue => e # rubocop:disable Style/RescueStandardError
          OpenTelemetry.logger.warn "Error in Propagator#extract #{e.message}"
          context
        end
      end
    end
  end
end
