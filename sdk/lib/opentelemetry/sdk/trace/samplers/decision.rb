# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Decision class represents an arbitrary sampling decision. It can
        # have a boolean value as a sampling decision and a collection of
        # attributes to be attached to a sampled root span.
        class Decision
          EMPTY_HASH = {}.freeze
          private_constant :EMPTY_HASH

          # Returns a frozen hash of attributes to be attached span. These
          # attributes should be added to the span only for root span or when
          # sampling decision {sampled?} changes from false to true.
          #
          # @return [Hash<String, Object>]
          attr_reader :attributes

          # Returns a new decision with the specified sampling decision and
          # attributes.
          #
          # @param [Boolean] decision Whether or not a span should be sampled
          # @param [optional Hash<String, Object>] attributes A frozen or freezable hash
          #   containing attributes to be attached to a root span
          def initialize(decision:, attributes: nil)
            @decision = decision
            @attributes = attributes.freeze || EMPTY_HASH
          end

          # Returns a sampling decision of whether this span should be sampled
          #
          # @return [Boolean] sampling decision
          def sampled?
            @decision
          end
        end
      end
    end
  end
end
