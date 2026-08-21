# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of Gauge.
      class Gauge
        # Record the current value for the Gauge
        #
        # @param [Numeric] amount The current absolute value.
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        def record(amount, attributes: {}); end

        # Returns whether this Gauge is enabled for recording measurements.
        #
        # @return [Boolean] default to true in noop implementation
        def enabled?
          true
        end

        # (Development) Binds a fixed set of attributes to this Gauge, returning an instrument
        # whose #record calls associate every measurement with those attributes. Attributes are
        # resolved once at bind time rather than on every recording, avoiding repeated attribute
        # processing and lookup. Passing attributes to #record on the returned bound instrument
        # negates this benefit.
        #
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        #
        # @return [Gauge] a bound instrument supporting #record; the no-op implementation returns self.
        def bind(attributes: {})
          self
        end
      end
    end
  end
end
