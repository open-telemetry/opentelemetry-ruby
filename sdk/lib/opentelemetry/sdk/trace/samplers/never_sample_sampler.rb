# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The {NeverSampleSampler} always returns a false sampling decision.
        class NeverSampleSampler < Sampler
          NEVER_SAMPLE_DECISION = Decision.new(decision: false)

          # Returns the sampling {Decision} for a {Span} to be created.
          #
          # @param [SpanContext] span_context The {SpanContext} of a parent span,
          #   typically extracted from the wire. Can be nil for a root span.
          # @param [Boolean] extracted_context True if span_context was extracted
          #   from the wire. Can be nil for a root span.
          # @param [String] trace_id The trace_id of the {Span} to be created
          # @param [String] span_id The span_id of the {Span} to be created
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
            NEVER_SAMPLE_DECISION
          end

          # Returns a description of the sampler.
          #
          # @return [String]
          def description
            'NeverSampleSampler'
          end
        end
      end
    end
  end
end
