# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # Implements sampling based on a probability.
        class ProbabilitySampler
          HINT_RECORD_AND_PROPAGATE = OpenTelemetry::Trace::SamplingHint::RECORD_AND_PROPAGATE
          HINT_RECORD = OpenTelemetry::Trace::SamplingHint::RECORD

          private_constant(:HINT_RECORD_AND_PROPAGATE, :HINT_RECORD)

          def initialize(probability, ignore_hints:, ignore_parent:, apply_to_remote_parent:, apply_to_all_spans:)
            @probability = probability
            @id_upper_bound = format('%016x', (probability * (2**64 - 1)).ceil)
            @ignored_hints = ignore_hints
            @use_parent_sampled_flag = !ignore_parent
            @apply_to_remote_parent = apply_to_remote_parent
            @apply_to_all_spans = apply_to_all_spans
          end

          # @api private
          #
          # Callable interface for probability sampler. See {Samplers}.
          def call(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:)
            # Ignored for sampling decision: links, name, kind, attributes.

            hint = nil if @ignored_hints.include?(hint)

            sampled = sample?(hint, trace_id, parent_context)
            recording = hint == HINT_RECORD || sampled

            if sampled && recording
              RECORD_AND_PROPAGATE
            elsif recording
              RECORD
            else
              NOT_RECORD
            end
          end

          private

          def sample?(hint, trace_id, parent_context)
            if parent_context.nil?
              hint == HINT_RECORD_AND_PROPAGATE || sample_trace_id?(trace_id)
            else
              parent_sampled?(parent_context) || hint == HINT_RECORD_AND_PROPAGATE || sample_trace_id_for_child?(parent_context, trace_id)
            end
          end

          def parent_sampled?(parent_context)
            @use_parent_sampled_flag && parent_context.trace_flags.sampled?
          end

          def sample_trace_id_for_child?(parent_context, trace_id)
            (@apply_to_all_spans || (@apply_to_remote_parent && parent_context.remote?)) && sample_trace_id?(trace_id)
          end

          def sample_trace_id?(trace_id)
            @probability == 1.0 || trace_id[16, 16] < @id_upper_bound
          end
        end
      end
    end
  end
end
