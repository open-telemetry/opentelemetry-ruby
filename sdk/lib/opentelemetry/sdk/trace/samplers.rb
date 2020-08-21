# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/decision'
require 'opentelemetry/sdk/trace/samplers/result'
require 'opentelemetry/sdk/trace/samplers/constant_sampler'
require 'opentelemetry/sdk/trace/samplers/parent_or_else'
require 'opentelemetry/sdk/trace/samplers/probability_sampler'

module OpenTelemetry
  module SDK
    module Trace
      # The Samplers module contains the sampling logic for OpenTelemetry. The
      # reference implementation provides a {ProbabilitySampler}, {ALWAYS_ON},
      # {ALWAYS_OFF}, and {ParentOrElse}.
      #
      # Custom samplers can be provided by SDK users. The required interface is:
      #
      #   should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:) -> Result
      #   description -> String
      #
      # Where:
      #
      # @param [String] trace_id The trace_id of the {Span} to be created.
      # @param [OpenTelemetry::Trace::SpanContext] parent_context The
      #   {OpenTelemetry::Trace::SpanContext} of a parent span, typically
      #   extracted from the wire. Can be nil for a root span.
      # @param [Enumerable<Link>] links A collection of links to be associated
      #   with the {Span} to be created. Can be nil.
      # @param [String] name Name of the {Span} to be created.
      # @param [Symbol] kind The {OpenTelemetry::Trace::SpanKind} of the {Span}
      #   to be created. Can be nil.
      # @param [Hash<String, Object>] attributes Attributes to be attached
      #   to the {Span} to be created. Can be nil.
      # @return [Result] The sampling result.
      module Samplers
        RECORD_AND_SAMPLED = Result.new(decision: Decision::RECORD_AND_SAMPLED)
        NOT_RECORD = Result.new(decision: Decision::NOT_RECORD)
        RECORD = Result.new(decision: Decision::RECORD)
        SAMPLING_HINTS = [Decision::NOT_RECORD, Decision::RECORD, Decision::RECORD_AND_SAMPLED].freeze

        private_constant(:RECORD_AND_SAMPLED, :NOT_RECORD, :RECORD, :SAMPLING_HINTS)

        # Returns a {Result} with {Decision::RECORD_AND_SAMPLED}.
        ALWAYS_ON = ConstantSampler.new(result: RECORD_AND_SAMPLED, description: 'AlwaysOnSampler')

        # Returns a {Result} with {Decision::NOT_RECORD}.
        ALWAYS_OFF = ConstantSampler.new(result: NOT_RECORD, description: 'AlwaysOffSampler')

        # Returns a new sampler. It either respects the parent span's sampling
        # decision or delegates to delegate_sampler for root spans.
        #
        # @param [Sampler] delegate_sampler The sampler to which the sampling
        #   decision is delegated for root spans.
        def self.parent_or_else(delegate_sampler)
          ParentOrElse.new(delegate_sampler)
        end

        # Convenience method. Equivalent to:
        #
        #   delegate = OpenTelemetry::SDK::Trace::Samplers.ALWAYS_ON
        #   OpenTelemetry::SDK::Trace::Samplers.parent_or_else(delegate)
        #
        # @return [ParentOrElse] returns a parent_or_else sampler
        def self.parent_or_always_on
          ParentOrElse.new(ALWAYS_ON)
        end

        # Convenience method. Equivalent to:
        #
        #   delegate = OpenTelemetry::SDK::Trace::Samplers.ALWAYS_OFF
        #   OpenTelemetry::SDK::Trace::Samplers.parent_or_else(delegate)
        #
        # @return [ParentOrElse] returns a parent_or_else sampler
        def self.parent_or_always_off
          ParentOrElse.new(ALWAYS_OFF)
        end

        # Convenience method. Equivalent to:
        #
        #   delegate = OpenTelemetry::SDK::Trace::Samplers.probability(probability)
        #   OpenTelemetry::SDK::Trace::Samplers.parent_or_else(delegate)
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        # @return [ParentOrElse] returns a parent_or_else sampler
        def self.parent_or_probability(probability)
          ParentOrElse.new(probability(probability))
        end

        # Returns a new sampler. The probability of sampling a trace is equal
        # to that of the specified probability.
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        # @raise [ArgumentError] if probability is out of range
        def self.probability(probability)
          raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)

          ProbabilitySampler.new(probability)
        end
      end
    end
  end
end
