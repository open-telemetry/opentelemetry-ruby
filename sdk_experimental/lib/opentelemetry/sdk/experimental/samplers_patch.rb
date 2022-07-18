# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

if !(%i[consistent_probability_based parent_consistent_probability_based] - OpenTelemetry::SDK::Trace::Samplers.singleton_methods).empty? &&
   !OpenTelemetry::SDK::Trace::Samplers.const_defined?(:ConsistentProbabilityTraceState) &&
   !OpenTelemetry::SDK::Trace::Samplers.const_defined?(:ParentConsistentProbabilityBased) &&
   !OpenTelemetry::SDK::Trace::Samplers.const_defined?(:ConsistentProbabilityBased)
  require 'opentelemetry/sdk/trace/samplers/consistent_probability_tracestate'
  require 'opentelemetry/sdk/trace/samplers/consistent_probability_based'
  require 'opentelemetry/sdk/trace/samplers/parent_consistent_probability_based'

  module OpenTelemetry
    module SDK
      module Experimental
        # The SamplersPatch module contains additional samplers for OpenTelemetry.
        module SamplersPatch
          # Returns a new sampler.
          #
          # @param [Numeric] ratio The desired sampling ratio.
          #   Must be within [0.0, 1.0].
          # @raise [ArgumentError] if ratio is out of range
          def consistent_probability_based(ratio)
            raise ArgumentError, 'ratio must be in range [0.0, 1.0]' unless (0.0..1.0).include?(ratio)

            ConsistentProbabilityBased.new(ratio)
          end

          # Returns a new sampler.
          #
          # @param [Sampler] root The sampler to which the sampling
          #   decision is delegated for spans with no parent (root spans).
          def parent_consistent_probability_based(root:)
            ParentConsistentProbabilityBased.new(root)
          end
        end
      end
    end
  end

  OpenTelemetry::SDK::Trace::Samplers.extend(OpenTelemetry::SDK::Experimental::SamplersPatch)
end
