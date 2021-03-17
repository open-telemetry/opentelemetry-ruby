# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A no-op text map propagator implementation
      class NoopTextMapPropagator
        EMPTY_LIST = [].freeze
        private_constant(:EMPTY_LIST)

        # Injects the provided context into a carrier.
        #
        # @param [Object] carrier A mutable carrier to inject context into.
        # @param [optional Context] context Context to be injected into carrier. Defaults
        #   to +Context.current+.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter); end

        # Extracts and returns context from a carrier. Returns the provided
        # context and logs a warning if an error if extraction fails.
        #
        # @param [Object] carrier The carrier to extract context from.
        # @param [optional Context] context Context to be updated with the state
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        #
        # @return [Context] a new context updated with state extracted from the
        #   carrier
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          context
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          EMPTY_LIST
        end
      end
    end
  end
end
