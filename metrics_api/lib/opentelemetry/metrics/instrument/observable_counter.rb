# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of ObservableCounter.
      class ObservableCounter
        # Observe the ObservableCounter with fixed timeout duration.
        #
        # @param [int] timeout The timeout duration for callback to run, which MUST be a non-negative numeric value.
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        def observe(timeout: nil, attributes: {}); end

        # Registers a callback function to report Measurements for this instrument.
        #
        # @param [Proc] callback the callback function
        def register_callback(callback); end

        # Unregisters a callback function previously registered via {#register_callback}.
        #
        # @param [Proc] callback the callback function
        def unregister(callback); end
      end
    end
  end
end
