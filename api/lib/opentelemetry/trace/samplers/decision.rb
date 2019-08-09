# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/samplers/basic_decision'

module OpenTelemetry
  module Trace
    module Samplers
      # The Decision class represents an arbitrary sampling decision. It can
      # have a boolean value as a sampling decision and a collection of
      # attributes to be attached to a sampled root span
      class Decision < BasicDecision
        # Returns a new decision with the specified sampling decision and
        # attributes
        #
        # @param [Boolean] decision Whether or not a span should be sampled
        # @param [Hash<String, Object>] attributes Attributes to be attached
        #   to a root span
        def initialize(decision:, attributes: nil)
          super(decision: decision)
          @attributes = attributes
        end

        # Returns attributes to be attached span. These attributes should be
        # added to the span only for root span or when sampling decision
        # {sampled?} changes from false to true.
        #
        # @return [Hash<String, Object>]
        def attributes
          @attributes ||= {}
        end
      end
    end
  end
end
