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
        APPLY_PROBABILITY_TO_SYMBOLS = %i[root_spans root_spans_and_remote_parent all_spans].freeze

        private_constant(:RECORD_AND_SAMPLED, :NOT_RECORD, :RECORD, :SAMPLING_HINTS, :APPLY_PROBABILITY_TO_SYMBOLS)

        # rubocop:disable Lint/UnusedBlockArgument

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

        # Returns a new sampler. The probability of sampling a trace is equal
        # to that of the specified probability.
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        # @param [optional Boolean] ignore_parent Whether to ignore parent
        #   sampling. Defaults to not ignore parent sampling.
        # @param [optional Symbol] apply_probability_to Whether to apply
        #   probability sampling to root spans, root spans and remote parents,
        #   or all spans. Allowed values include :root_spans, :root_spans_and_remote_parent,
        #   and :all_spans. Defaults to :root_spans_and_remote_parent.
        # @raise [ArgumentError] if probability is out of range
        # @raise [ArgumentError] if apply_probability_to is not one of the allowed symbols
        def self.probability(probability,
                             ignore_parent: false,
                             apply_probability_to: :root_spans_and_remote_parent)
          raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)
          raise ArgumentError, 'apply_probability_to' unless APPLY_PROBABILITY_TO_SYMBOLS.include?(apply_probability_to)

          ProbabilitySampler.new(probability,
                                 ignore_parent: ignore_parent,
                                 apply_to_remote_parent: apply_probability_to != :root_spans,
                                 apply_to_all_spans: apply_probability_to == :all_spans)
        end
      end
    end
  end
end
