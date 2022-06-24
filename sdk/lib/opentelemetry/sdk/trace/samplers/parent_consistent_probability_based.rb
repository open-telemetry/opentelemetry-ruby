# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # The ParentConsistentProbabilityBased sampler is meant as an optional
        # replacement for the ParentBased sampler. It is required to first validate
        # the tracestate and then respect the sampled flag in the W3C traceparent.
        #
        # The ParentConsistentProbabilityBased Sampler constructor takes a single
        # Sampler argument, which is the Sampler to use in case the
        # ParentConsistentProbabilityBased Sampler is called for a root span.
        class ParentConsistentProbabilityBased
          DECIMAL = /\A\d+\z/.freeze
          private_constant(:DECIMAL)

          def initialize(root)
            @root = root
          end

          def ==(other)
            @root == other.root
          end

          # @api private
          #
          # See {Samplers}.
          def description
            "ParentConsistentProbabilityBased{root=#{@root.description}}"
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            parent_span_context = OpenTelemetry::Trace.current_span(parent_context).context
            if !parent_span_context.valid?
              @root.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
            else
              tracestate = validate_tracestate(parent_span_context)
              if parent_span_context.trace_flags.sampled?
                Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
              else
                Result.new(decision: Decision::DROP, tracestate: tracestate)
              end
            end
          end

          protected

          attr_reader :root

          private

          def validate_tracestate(span_context)
            sampled = span_context.trace_flags.sampled?
            tracestate = span_context.tracestate
            ot = OpenTelemetry::SDK::Trace::Tracestate.from_tracestate(tracestate)
            r = decimal(ot.value('r'))
            p = decimal(ot.value('p'))
            new_ot = ot
            new_ot = ot.delete('p') if !p.nil? && p > 63
            new_ot = ot.delete('p').delete('r') if !r.nil? && r > 62
            new_ot = ot.delete('p') if !p.nil? && !r.nil? && !invariant(p, r, sampled)
            if new_ot != ot
              new_ot.this_is_a_deliberately_terrible_name_please_bikeshed(tracestate)
            else
              tracestate
            end
          end

          def invariant(p, r, sampled)
            ((p <= r) == sampled) || (sampled && (p == 63))
          end

          def decimal(s)
            return nil if s.nil? || !DECIMAL.match?(s)

            s.to_i
          end
        end
      end
    end
  end
end
