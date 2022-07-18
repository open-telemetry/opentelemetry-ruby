# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/consistent_probability_tracestate'
require 'opentelemetry/sdk/trace/samplers/consistent_probability_based'
require 'opentelemetry/sdk/trace/samplers/parent_consistent_probability_based'

module OpenTelemetry
  module SDK
    module Trace
      # The Samplers module contains the sampling logic for OpenTelemetry. The
      # reference implementation provides a {TraceIdRatioBased}, {ALWAYS_ON},
      # {ALWAYS_OFF}, and {ParentBased}.
      #
      # Custom samplers can be provided by SDK users. The required interface is:
      #
      #   should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:) -> Result
      #   description -> String
      #
      # Where:
      #
      # @param [String] trace_id The trace_id of the {Span} to be created.
      # @param [OpenTelemetry::Context] parent_context The
      #   {OpenTelemetry::Context} with a parent {Span}. The {Span}'s
      #   {OpenTelemetry::Trace::SpanContext} may be invalid to indicate a
      #   root span.
      # @param [Enumerable<Link>] links A collection of links to be associated
      #   with the {Span} to be created. Can be nil.
      # @param [String] name Name of the {Span} to be created.
      # @param [Symbol] kind The {OpenTelemetry::Trace::SpanKind} of the {Span}
      #   to be created. Can be nil.
      # @param [Hash<String, Object>] attributes Attributes to be attached
      #   to the {Span} to be created. Can be nil.
      # @return [Result] The sampling result.
      module Samplers
        # Returns a new sampler.
        #
        # @param [Numeric] ratio The desired sampling ratio.
        #   Must be within [0.0, 1.0].
        # @raise [ArgumentError] if ratio is out of range
        def self.consistent_probability_based(ratio)
          raise ArgumentError, 'ratio must be in range [0.0, 1.0]' unless (0.0..1.0).include?(ratio)

          ConsistentProbabilityBased.new(ratio)
        end

        # Returns a new sampler.
        #
        # @param [Sampler] root The sampler to which the sampling
        #   decision is delegated for spans with no parent (root spans).
        def self.parent_consistent_probability_based(root:)
          ParentConsistentProbabilityBased.new(root)
        end
      end
    end
  end
end
