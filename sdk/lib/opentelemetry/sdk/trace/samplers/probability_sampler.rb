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
            ignore(links, name, kind, attributes)
            hint = filter_hint(hint)

            sampled_flag = sample(hint, trace_id, parent_context)
            record_events = hint == HINT_RECORD || sampled_flag

            if sampled_flag && record_events
              RECORD_AND_PROPAGATE
            elsif record_events
              RECORD
            else
              NOT_RECORD
            end
          end

          private

          # Explicitly ignore these parameters.
          def ignore(_links, _name, _kind, _attributes); end

          def filter_hint(hint)
            hint unless @ignored_hints.include?(hint)
          end

          def sample(hint, trace_id, parent_context)
            if parent_context.nil?
              hint == HINT_RECORD_AND_PROPAGATE || probably(trace_id)
            else
              parent_sampled_flag(parent_context) || hint == HINT_RECORD_AND_PROPAGATE || probably_for_child(parent_context, trace_id)
            end
          end

          def parent_sampled_flag(parent_context)
            @use_parent_sampled_flag && parent_context.trace_flags.sampled?
          end

          def probably_for_child(parent_context, trace_id)
            (@apply_to_all_spans || (@apply_to_remote_parent && parent_context.remote?)) && probably(trace_id)
          end

          def probably(trace_id)
            @probability == 1.0 || trace_id[16, 16] < @id_upper_bound
          end
        end
      end
    end
  end
end
