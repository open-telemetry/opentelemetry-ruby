# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of ObservableUpDownCounter.
      class ObservableUpDownCounter
        # Observe the ObservableUpDownCounter with fixed timeout duration.
        # Everytime observe, the value should be sent to backend through exporter
        #
        # @param [int] timeout The timeout duration for callback to run, which MUST be a non-negative numeric value.
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        def observe(timeout: nil, attributes: {}); end
      end
    end
  end
end
