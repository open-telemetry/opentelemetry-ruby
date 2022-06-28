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
        # The ConsistentProbabilityTraceState module implements common TraceState
        # validation and manipulation for the consistent probability-based samplers.
        module ConsistentProbabilityTraceState
          DECIMAL = /\A\d+\z/.freeze
          private_constant(:DECIMAL)

          def validate_tracestate(span_context) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            sampled = span_context.trace_flags.sampled?
            tracestate = span_context.tracestate
            ot = OpenTelemetry::SDK::Trace::Tracestate.from_tracestate(tracestate)
            r = decimal(ot.value('r'))
            p = decimal(ot.value('p'))
            new_ot = ot
            new_ot = ot.delete('p') if !p.nil? && p > 63
            new_ot = ot.delete('p').delete('r') if !r.nil? && r > 62
            r = nil if !r.nil? && r > 62 # TODO: clean up this logic
            new_ot = ot.delete('p') if !p.nil? && !r.nil? && !invariant(p, r, sampled)
            new_ot = yield new_ot, r, p if block_given?
            if new_ot != ot
              new_ot.this_is_a_deliberately_terrible_name_please_bikeshed(tracestate)
            else
              tracestate
            end
          end

          def invariant(p, r, sampled) # rubocop:disable Naming/UncommunicativeMethodParamName
            ((p <= r) == sampled) || (sampled && (p == 63))
          end

          def decimal(str)
            str.to_i if !str.nil? && DECIMAL.match?(str)
          end
        end
      end
    end
  end
end
