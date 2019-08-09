# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Samplers
      # This class represents a BasicDecision, which is a utility class used
      # by the {AlwaysSampleSampler} and the {NeverSampleSampler}. A
      # BasicDecision can have boolean sampling decision and will always return
      # an empty set of attributes
      class BasicDecision
        # Returns a new decision with the specified sampling decision and
        # and empty attributes
        #
        # @param [Boolean] decision Whether a span should be sampled
        def initialize(decision:)
          @decision = decision
        end

        # Returns a sampling decision of whether this span should be sampled
        #
        # @return [Boolean] sampling decision
        def sampled?
          @decision
        end

        # Always returns an empty set of attributes
        #
        # @return [Hash<String,String>]
        def attributes
          {}
        end
      end
    end
  end
end
