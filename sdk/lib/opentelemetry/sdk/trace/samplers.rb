# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/decision'
require 'opentelemetry/sdk/trace/samplers/result'
require 'opentelemetry/sdk/trace/samplers/probability_sampler'

module OpenTelemetry
  module SDK
    module Trace
      # The Samplers module contains the sampling logic for OpenTelemetry. The
      # reference implementation provides a {ProbabilitySampler}, {ALWAYS_ON},
      # {ALWAYS_OFF}, and {ALWAYS_PARENT}.
      #
      # Custom samplers can be provided by SDK users. The required interface is
      # a callable with the signature:
      #
      #   (trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) -> Result
      #
      # Where:
      #
      # @param [String] trace_id The trace_id of the {Span} to be created.
      # @param [String] span_id The span_id of the {Span} to be created.
      # @param [OpenTelemetry::Trace::SpanContext] parent_context The
      #   {OpenTelemetry::Trace::SpanContext} of a parent span, typically
      #   extracted from the wire. Can be nil for a root span.
      # @param [Symbol] hint A {OpenTelemetry::Trace::SamplingHint} about
      #   whether the {Span} should be sampled and/or record events.
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

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_SAMPLED}.
        ALWAYS_ON = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { RECORD_AND_SAMPLED }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::NOT_RECORD}.
        ALWAYS_OFF = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { NOT_RECORD }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_SAMPLED} if the parent context is sampled or
        # {Decision::NOT_RECORD} otherwise, or if there is no parent context.
        # rubocop:disable Style/Lambda
        ALWAYS_PARENT = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) do
          if parent_context&.trace_flags&.sampled?
            RECORD_AND_SAMPLED
          else
            NOT_RECORD
          end
        end
        # rubocop:enable Style/Lambda
        # rubocop:enable Lint/UnusedBlockArgument

        # Returns a new sampler. The probability of sampling a trace is equal
        # to that of the specified probability.
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        # @param [optional Enumerable<Symbol>] ignore_hints Sampling hints to
        #   ignore. Defaults to ignore {OpenTelemetry::Trace::SamplingHint::RECORD}.
        # @param [optional Boolean] ignore_parent Whether to ignore parent
        #   sampling. Defaults to not ignore parent sampling.
        # @param [optional Symbol] apply_probability_to Whether to apply
        #   probability sampling to root spans, root spans and remote parents,
        #   or all spans. Allowed values include :root_spans, :root_spans_and_remote_parent,
        #   and :all_spans. Defaults to :root_spans_and_remote_parent.
        # @raise [ArgumentError] if probability is out of range
        # @raise [ArgumentError] if ignore_hints contains invalid hints
        # @raise [ArgumentError] if apply_probability_to is not one of the allowed symbols
        def self.probability(probability,
                             ignore_hints: [OpenTelemetry::Trace::SamplingHint::RECORD],
                             ignore_parent: false,
                             apply_probability_to: :root_spans_and_remote_parent)
          raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)
          raise ArgumentError, 'ignore_hints' unless (ignore_hints.to_a - SAMPLING_HINTS).empty?
          raise ArgumentError, 'apply_probability_to' unless APPLY_PROBABILITY_TO_SYMBOLS.include?(apply_probability_to)

          ProbabilitySampler.new(probability,
                                 ignore_hints: ignore_hints.to_a,
                                 ignore_parent: ignore_parent,
                                 apply_to_remote_parent: apply_probability_to != :root_spans,
                                 apply_to_all_spans: apply_probability_to == :all_spans)
        end
      end
    end
  end
end
