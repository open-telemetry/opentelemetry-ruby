# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A composite propagator composes a list of injectors and extractors into
      # single interface exposing inject and extract methods. Injection and
      # extraction will preserve the order of the injectors and extractors
      # passed in during initialization.
      class CompositePropagator
        # Returns a Propagator that extracts using the provided extractors
        # and injectors.
        #
        # @param [Array<#inject>] injectors
        # @param [Array<#extract>] extractors
        def initialize(injectors, extractors)
          @injectors = injectors
          @extractors = extractors
        end

        # Runs injectors in order and returns a carrier. If an injection fails
        # a warning will be logged and remaining injectors will be executed.
        # Always returns a valid carrier.
        #
        # @param [Object] carrier A carrier to inject context into
        #   context into
        # @param [optional Context] context Context to be injected into carrier.
        #   Defaults to +Context.current+
        # @param [optional Callable] setter An optional callable that takes a
        #   carrier, a key and a value and assigns the key-value pair in the
        #   carrier. If omitted the default setter will be used which expects
        #   the carrier to respond to [] and []=.
        #
        # @return [Object] carrier
        def inject(carrier, context = Context.current, &setter)
          @injectors.inject(carrier) do |memo, injector|
            injector.inject(memo, context, &setter)
          rescue => e # rubocop:disable Style/RescueStandardError
            OpenTelemetry.logger.warn "Error in CompositePropagator#inject #{e.message}"
            carrier
          end
        end

        # Runs extractors in order and returns a Context updated with the
        # results of each extraction. If an extraction fails, a warning will be
        # logged and remaining extractors will continue to be executed. Always
        # returns a valid context.
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
          @extractors.inject(context) do |ctx, extractor|
            begin
              extractor.extract(carrier, ctx, &getter)
            rescue => e # rubocop:disable Style/RescueStandardError
              OpenTelemetry.logger.warn "Error in CompositePropagator#extract #{e.message}"
              ctx
            end
          end
        end
      end
    end
  end
end
