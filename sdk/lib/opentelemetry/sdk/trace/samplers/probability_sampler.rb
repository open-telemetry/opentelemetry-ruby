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
          attr_reader :description

          def initialize(probability, ignore_parent:, apply_to_remote_parent:, apply_to_all_spans:)
            @probability = probability
            @id_upper_bound = format('%016x', (probability * (2**64 - 1)).ceil)
            @use_parent_sampled_flag = !ignore_parent
            @apply_to_remote_parent = apply_to_remote_parent
            @apply_to_all_spans = apply_to_all_spans
            @description = format('ProbabilitySampler{%.6f}', probability)
          end

          # @api private
          #
          # See {Samplers#should_sample?}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            # Ignored for sampling decision: links, name, kind, attributes.

            if sample?(trace_id, parent_context)
              RECORD_AND_SAMPLED
            else
              NOT_RECORD
            end
          end

          private

          def sample?(trace_id, parent_context)
            if parent_context.nil?
              sample_trace_id?(trace_id)
            else
              parent_sampled?(parent_context) || sample_trace_id_for_child?(parent_context, trace_id)
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
