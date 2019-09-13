# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk/trace/samplers/decision'
require 'opentelemetry/sdk/trace/samplers/hint'
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
      # @param [String] trace_id
      # @param [String] span_id
      # @param [OpenTelemetry::Trace::SpanContext] parent_context
      # @param [Hint] hint
      # @param [Enumerable<Link>] links
      # @param [String] name
      # @param [Symbol] kind
      # @param [Hash<String, Object>] attributes
      # @return [Result]
      module Samplers
        RECORD_AND_PROPAGATE = Result.new(decision: Decision::RECORD_AND_PROPAGATE)
        NOT_RECORD = Result.new(decision: Decision::NOT_RECORD)

        private_constant(:RECORD_AND_PROPAGATE, :NOT_RECORD)

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_PROPAGATE}.
        ALWAYS_ON = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { RECORD_AND_PROPAGATE }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::NOT_RECORD}.
        ALWAYS_OFF = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) { NOT_RECORD }

        # Ignores all values in hint and returns a {Result} with
        # {Decision::RECORD_AND_PROPAGATE} if the parent context is sampled or
        # {Decision::NOT_RECORD} otherwise, or if there is no parent context.
        ALWAYS_PARENT = ->(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:) do
          if parent_context&.trace_flags&.sampled?
            RECORD_AND_PROPAGATE
          else
            NOT_RECORD
          end
        end
      end
    end
  end
end
