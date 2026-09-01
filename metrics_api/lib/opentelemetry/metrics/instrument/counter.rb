# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of Counter.
      class Counter
        # Increment the Counter by a fixed amount.
        #
        # @param [numeric] increment The increment amount, which MUST be a non-negative numeric value.
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        def add(increment, attributes: {}); end

        # Returns whether this Counter is enabled for recording measurements.
        #
        # @return [Boolean] default to true in noop implementation
        def enabled?
          true
        end

        # (Development) Binds a fixed set of attributes to this Counter, returning an instrument
        # whose #add calls associate every measurement with those attributes. Attributes are resolved
        # once at bind time rather than on every recording, avoiding repeated attribute processing and
        # lookup. Passing attributes to #add on the returned bound instrument negates this benefit.
        #
        # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   Values must be non-nil and (array of) string, boolean or numeric type.
        #   Array values must not contain nil elements and all elements must be of
        #   the same basic type (string, numeric, boolean).
        #
        # @return [Counter] a bound instrument supporting #add; the no-op implementation returns self.
        def bind(attributes: {})
          self
        end
      end
    end
  end
end
