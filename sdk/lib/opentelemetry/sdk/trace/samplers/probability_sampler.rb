# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # A {OpenTelemetry::Trace::Samplers::Sampler} where the probability of
        # sampling a trace is equal to that of the specified probability.
        class ProbabilitySampler
          class << self
            private :new # rubocop:disable Style/AccessModifierDeclarations

            # Returns a new {OpenTelemetry::Trace::Samplers::Sampler}. The
            # probability of sampling a trace is equal to that of the specified
            # probability.
            #
            # @param [Numeric] probability The desired probability of sampling.
            #   Must be within [0.0, 1.0].
            # @raise [ArgumentError] if probability is out of range
            # @return [OpenTelemetry::Trace::Samplers::Sampler]
            def create(probability)
              raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)

              return AlwaysSampleSampler.new if probability == 1.0

              new(probability)
            end
          end

          # @api private
          # The constructor is private and only for use internally by the
          # class. Users should use the {create} factory method to obtain a
          # {ProbabilitySampler} instance.
          #
          # @param [Numeric] probability The desired probability of sampling.
          #   Must be within [0.0, 1.0].
          # @return [ProbabilitySampler]
          def initialize(probability)
            @description = format('ProbabilitySampler{%.6f}', probability)
            @id_upper_bound = format('%016x', (probability * (2**64 - 1)).ceil)
          end

          SAMPLE_DECISION = Result.new(decision: Decision::RECORD_AND_PROPAGATE)
          DONT_SAMPLE_DECISION = Result.new(decision: Decision::NOT_RECORD)

          private_constant(:SAMPLE_DECISION, :DONT_SAMPLE_DECISION)

          # Returns the sampling {OpenTelemetry::Trace::Samplers::Decision} for a
          # {Span} to be created
          #
          # @param [SpanContext] span_context The
          #   {OpenTelemetry::Trace::SpanContext} of a parent span, typically
          #   extracted from the wire. Can be nil for a root span.
          # @param [Boolean] extracted_context True if span_context was extracted
          #   from the wire. Can be nil for a root span.
          # @param [String] trace_id The trace_id of the {Span} to be created
          # @param [String] span_id The span_id of the {Span} to be created
          # @param [String] span_name Name of the {Span} to be created
          # @param [Enumerable<Link>] links A collection of links to be associated
          #   with the {Span} to be created. Can be nil.
          # @return [Decision] The sampling decision
          def call(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:)
            # If the parent is sampled keep the sampling decision.
            if span_context&.trace_flags&.sampled?
              SAMPLE_DECISION
            elsif links&.any? { |link| link.context.trace_flags.sampled? }
              # If any parent link is sampled keep the sampling decision.
              SAMPLE_DECISION
            elsif trace_id[16, 16] < @id_upper_bound
              SAMPLE_DECISION
            else
              DONT_SAMPLE_DECISION
            end
          end

          # Returns a description of the sampler
          #
          # @return [String]
          attr_reader :description
        end
      end
    end
  end
end
