# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # In situations where performance is a requirement and a metric is
    # repeatedly used with the same set of labels, the developer may elect to
    # use instrument {Handles} as an optimization. For handles to be a benefit,
    # it requires that a specific instrument will be re-used with specific
    # labels. If an instrument will be used with the same label set more than
    # once, obtaining an instrument handle corresponding to the label set
    # ensures the highest performance available.
    #
    # To obtain a handle given an instrument and label set, use the  #handle
    # method to return an interface that supports the #add, #set, or #record
    # method of the instrument in question.
    #
    # Instrument handles may consume SDK resources indefinitely.
    module Handles
      # A float gauge handle.
      class FloatGauge
        def set(value); end
      end

      # An integer gauge handle.
      class IntegerGauge
        def set(value); end
      end

      # A float counter handle.
      class FloatCounter
        def add(value); end
      end

      # An integer counter handle.
      class IntegerCounter
        def add(value); end
      end

      # A float measure handle.
      class FloatMeasure
        def record(value); end
      end

      # An integer measure handle.
      class IntegerMeasure
        def record(value); end
      end
    end
  end
end
