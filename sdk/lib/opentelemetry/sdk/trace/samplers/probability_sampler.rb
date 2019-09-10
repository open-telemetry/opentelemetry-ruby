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
        class ProbabilitySampler < OpenTelemetry::Trace::Samplers::Sampler
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

              return OpenTelemetry::Trace::Samplers::AlwaysSampleSampler.new if probability == 1.0

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
            @probability = probability
          end

          SAMPLE_DECISION = OpenTelemetry::Trace::Samplers::Decision.new(decision: true)
          DONT_SAMPLE_DECISION = OpenTelemetry::Trace::Samplers::Decision.new(decision: false)

          private_constant(:SAMPLE_DECISION, :DONT_SAMPLE_DECISION)

          # Returns the sampling {OpenTelemetry::Trace::Samplers::Decision} for a
          # {Span} to be created
          #
          # @param [SpanContext] span_context The
          #   {OpenTelemetry::Trace::SpanContext} of a parent span, typically
          #   extracted from the wire. Can be nil for a root span.
          # @param [Boolean] extracted_context True if span_context was extracted
          #   from the wire. Can be nil for a root span.
          # @param [Integer] trace_id The trace_id of the {Span} to be created
          # @param [Integer] span_id The span_id of the {Span} to be created
          # @param [String] span_name Name of the {Span} to be created
          # @param [Enumerable<Link>] links A collection of links to be associated
          #   with the {Span} to be created. Can be nil.
          # @return [Decision] The sampling decision
          def decision(span_context: nil,
                       extracted_context: nil,
                       trace_id:,
                       span_id:,
                       span_name:,
                       links: nil)
            super

            # If the parent is sampled keep the sampling decision.
            if span_context&.trace_flags&.sampled?
              SAMPLE_DECISION
            elsif links&.any? { |link| link.context.trace_flags.sampled? }
              # If any parent link is sampled keep the sampling decision.
              SAMPLE_DECISION
            elsif rand < @probability
              SAMPLE_DECISION
            else
              DONT_SAMPLE_DECISION
            end
          end

          # Returns a description of the sampler
          #
          # @return [String]
          def description
            format('ProbabilitySampler{%.6f}', @probability)
          end
        end
      end
    end
  end
end
