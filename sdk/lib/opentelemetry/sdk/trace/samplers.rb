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
        RECORD_AND_PROPAGATE = Result.new(decision: Decision::RECORD_AND_PROPAGATE)
        NOT_RECORD = Result.new(decision: Decision::NOT_RECORD)
        SAMPLING_HINTS = [Decision::NOT_RECORD, Decision::RECORD, Decision::RECORD_AND_PROPAGATE].freeze

        private_constant(:RECORD_AND_PROPAGATE, :NOT_RECORD, :SAMPLING_HINTS)

        # rubocop:disable Lint/UnusedBlockArgument

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_PROPAGATE}.
        ALWAYS_ON = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { RECORD_AND_PROPAGATE }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::NOT_RECORD}.
        ALWAYS_OFF = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { NOT_RECORD }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_PROPAGATE} if the parent context is sampled or
        # {Decision::NOT_RECORD} otherwise, or if there is no parent context.
        # rubocop:disable Style/Lambda
        ALWAYS_PARENT = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) do
          if parent_context&.trace_flags&.sampled?
            RECORD_AND_PROPAGATE
          else
            NOT_RECORD
          end
        end
        # rubocop:enable Style/Lambda

        # Returns a new sampling closure. The probability of sampling a trace
        # is equal to that of the specified probability.
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        # @param [optional Enumerable<Symbol>] ignore_hints Sampling hints to
        #   ignore. Defaults to ignore {OpenTelemetry::Trace::SamplingHint::RECORD}.
        # @param [optional Boolean] ignore_parent Whether to ignore parent
        #   sampling. Defaults to not ignore parent sampling.
        # @param [optional Boolean] apply_to_root_spans Whether to apply
        #   probability sampling to root spans. Defaults to true.
        # @param [optional Boolean] apply_to_remote_parent Whether to apply
        #   probability sampling to remote parent. Defaults to true.
        # @param [optional Boolean] apply_to_all_spans Whether to apply
        #   probability sampling to all spans. Defaults to false.
        # @raise [ArgumentError] if probability is out of range
        # @return [OpenTelemetry::Trace::Samplers::Sampler]
        def self.probability(probability,
                             ignore_hints: [OpenTelemetry::Trace::SamplingHint::RECORD],
                             ignore_parent: false,
                             apply_to_root_spans: true,
                             apply_to_remote_parent: true,
                             apply_to_all_spans: false)
          raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)
          raise ArgumentError, 'ignore_hints' unless (ignore_hints.to_a - SAMPLING_HINTS).empty?
          raise ArgumentError if apply_to_all_spans && (!apply_to_root_spans || !apply_to_remote_parent)

          hints = SAMPLING_HINTS - ignore_hints.to_a
          result_from_hint = hints.map { |hint| [hint, Result.new(decision: hint)] }.to_h.freeze
          ProbabilitySampler.new(probability,
                                 result_from_hint: result_from_hint,
                                 ignore_parent: ignore_parent,
                                 apply_to_root_spans: apply_to_root_spans,
                                 apply_to_remote_parent: apply_to_remote_parent,
                                 apply_to_all_spans: apply_to_all_spans)
        end
        # rubocop:enable Lint/UnusedBlockArgument
      end
    end
  end
end
