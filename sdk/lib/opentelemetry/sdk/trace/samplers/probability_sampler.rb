# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api internal
        class ProbabilitySampler
          def initialize(probability, result_from_hint:, ignore_parent:, apply_to_root_spans:, apply_to_remote_parent:, apply_to_all_spans:)
            @probability = probability
            @id_upper_bound = format('%016x', (probability * (2**64 - 1)).ceil)
            @result_from_hint = result_from_hint
            @ignore_parent = ignore_parent
            @apply_to_root_spans = apply_to_root_spans
            @apply_to_remote_parent = apply_to_remote_parent
            @apply_to_all_spans = apply_to_all_spans
          end

          def call(trace_id:, span_id:, parent_context:, hint:, links:, name:, kind:, attributes:)
            take_hint(hint) ||
              use_parent_sampling(parent_context) ||
              use_link_sampling(links) ||
              dont_apply_to_root_span(parent_context) ||
              dont_apply_to_remote_parent(parent_context) ||
              dont_apply_to_local_child(parent_context) ||
              use_probability_sampling(trace_id) ||
              NOT_RECORD
          end

          private

          # Take the hint if one is provided and we're not ignoring it.
          def take_hint(hint)
            @result_from_hint[hint] if hint
          end

          # If the parent is sampled and we're not ignoring it keep the sampling decision.
          def use_parent_sampling(parent_context)
            RECORD_AND_PROPAGATE if !@ignore_parent && parent_context&.trace_flags&.sampled?
          end

          # If any link is sampled keep the sampling decision.
          def use_link_sampling(links)
            RECORD_AND_PROPAGATE if links&.any? { |link| link.context.trace_flags.sampled? }
          end

          def dont_apply_to_root_span(parent_context)
            NOT_RECORD if !@apply_to_root_spans && parent_context.nil?
          end

          def dont_apply_to_remote_parent(parent_context)
            NOT_RECORD if !@apply_to_remote_parent && parent_context&.remote?
          end

          def dont_apply_to_local_child(parent_context)
            NOT_RECORD if !@apply_to_all_spans && parent_context && !parent_context.remote?
          end

          def use_probability_sampling(trace_id)
            RECORD_AND_PROPAGATE if @probability == 1.0 || trace_id[16, 16] < @id_upper_bound
          end
        end
      end
    end
  end
end
