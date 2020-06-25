# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/probability_sampler'
require 'opentelemetry/sdk/trace/samplers/decision'
require 'opentelemetry/sdk/trace/samplers/result'

module OpenTelemetry
  module Exporters
    module Datadog
      # Implements sampling based on a probability but records all spans regardless.
      class DatadogProbabilitySampler < OpenTelemetry::SDK::Trace::Samplers::ProbabilitySampler
        RECORD_AND_SAMPLED = OpenTelemetry::SDK::Trace::Samplers::Result.new(decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLED)
        RECORD = OpenTelemetry::SDK::Trace::Samplers::Result.new(decision: OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD)

        private_constant(:RECORD_AND_SAMPLED, :RECORD)

        # @api private
        #
        # See {Samplers}.
        def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
          # Ignored for sampling decision: links, name, kind, attributes.

          if sample?(trace_id, parent_context)
            RECORD_AND_SAMPLED
          else
            RECORD
          end
        end

        # Returns a new sampler. The probability of sampling a trace is equal
        # to that of the specified probability.
        #
        # @param [Numeric] probability The desired probability of sampling.
        #   Must be within [0.0, 1.0].
        def self.default_with_probability(probability = 1.0)
          raise ArgumentError, 'probability must be in range [0.0, 1.0]' unless (0.0..1.0).include?(probability)

          new(probability,
              ignore_parent: false,
              apply_to_remote_parent: :root_spans_and_remote_parent,
              apply_to_all_spans: :root_spans_and_remote_parent)
        end

        DEFAULT = new(1.0,
                      ignore_parent: false,
                      apply_to_remote_parent: :root_spans_and_remote_parent,
                      apply_to_all_spans: :root_spans_and_remote_parent)
      end
    end
  end
end
