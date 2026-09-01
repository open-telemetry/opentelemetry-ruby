# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of UpDownCounter.
      class UpDownCounter
        # Increment or decrement the UpDownCounter by a fixed amount.
        #
        # @param [Numeric] amount The amount to be added, can be positive, negative or zero.
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        def add(amount, attributes: {}); end

        # Returns whether this UpDownCounter is enabled for recording measurements.
        #
        # @return [Boolean] default to true in noop implementation
        def enabled?
          true
        end

        # (Development) Binds a fixed set of attributes to this UpDownCounter, returning an instrument
        # whose #add calls associate every measurement with those attributes. Attributes are resolved
        # once at bind time rather than on every recording, avoiding repeated attribute processing and
        # lookup. Passing attributes to #add on the returned bound instrument negates this benefit.
        #
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        #
        # @return [UpDownCounter] a bound instrument supporting #add; the no-op implementation returns self.
        def bind(attributes: {})
          self
        end
      end
    end
  end
end
