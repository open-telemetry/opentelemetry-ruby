# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Result class represents an arbitrary sampling result. It has
        # boolean values for the sampling decision and whether to record
        # events, and a collection of attributes to be attached to a sampled
        # root span.
        class Result
          EMPTY_HASH = {}.freeze
          DECISIONS = [Decision::RECORD, Decision::NOT_RECORD, Decision::RECORD_AND_PROPAGATE].freeze
          private_constant(:EMPTY_HASH, :DECISIONS)

          # Returns a frozen hash of attributes to be attached span.
          #
          # @return [Hash<String, Object>]
          attr_reader :attributes

          # Returns a new sampling result with the specified decision and
          # attributes.
          #
          # @param [Symbol] decision Whether or not a span should be sampled
          #   and/or record events.
          # @param [optional Hash<String, Object>] attributes A frozen or freezable hash
          #   containing attributes to be attached to the span.
          def initialize(decision:, attributes: nil)
            raise ArgumentError, 'decision' unless DECISIONS.include?(decision)

            @decision = decision
            @attributes = attributes.freeze || EMPTY_HASH
          end

          # Returns true if this span should be sampled.
          #
          # @return [Boolean] sampling decision
          def sampled?
            @decision == Decision::RECORD_AND_PROPAGATE
          end

          # Returns true if this span should record events.
          #
          # @return [Boolean] recording decision
          def record_events?
            @decision != Decision::NOT_RECORD
          end
        end
      end
    end
  end
end
