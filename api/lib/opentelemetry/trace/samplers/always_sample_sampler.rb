# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/samplers/basic_decision'

module OpenTelemetry
  module Trace
    module Samplers
      # The {AlwaysSampleSampler} always returns a true sampling decision.
      class AlwaysSampleSampler
        ALWAYS_SAMPLE_DECISION = BasicDecision.new(decision: true)

        # Returns the sampling {Decision} for a {Span} to be created
        #
        # @param [SpanContext] span_context The {SpanContext} of a parent span,
        #   typically extracted from the wire. Can be nil.
        # @param [Boolean] extracted_context True if span_context was extracted
        #   from the wire. Can be nil.
        # @param [Integer] trace_id The trace_id of the {Span} to be created
        # @param [Integer] span_id The span_id of the {Span} to be created
        # @param [String] span_name Name of the {Span} to be created
        # @param [Enumerable<Link>] links A collection of {Link links} to be associated
        #   with the {Span} to be created. Can be nil.
        # @return [Decision] The sampling decision
        def should_sample(span_context: nil,
                          extracted_context: nil,
                          trace_id:,
                          span_id:,
                          span_name:,
                          links: nil)
          ALWAYS_SAMPLE_DECISION
        end

        # Returns a description of the sampler
        #
        # @return [String]
        def description
          'AlwaysSampleSampler'
        end
      end
    end
  end
end
