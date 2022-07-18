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
        # The ConsistentProbabilityTraceState module implements Tracestate parsing,
        # validation and manipulation for the consistent probability-based samplers.
        module ConsistentProbabilityTraceState
          DECIMAL = /\A\d+\z/.freeze
          private_constant(:DECIMAL)

          # parse_ot_vendor_tag parses the 'ot' vendor tag of the tracestate.
          # It yields the parsed probability fields and the remaining tracestate.
          # It returns the result of the block.
          def parse_ot_vendor_tag(tracestate)
            return yield(nil, nil, nil) if tracestate.empty?

            ot = tracestate.value('ot')
            return yield(nil, nil, nil) if ot.nil? || ot.length > MAX_LIST_LENGTH # TODO: warn that we're rejecting the tracestate

            p = r = nil
            rest = +''
            ot.split(';').each do |field|
              k, v = field.split(':', 2)
              # TODO: "the used keys MUST be unique." - do we need to validate this?
              case k
              when 'p' then p = decimal(v)
              when 'r' then r = decimal(v)
              else
                rest << ';' unless rest.empty?
                rest << field
              end
            end
            rest = nil if rest.empty?
            yield(p, r, rest)
          end

          def update_tracestate(tracestate, p, r, rest) # rubocop:disable Naming/UncommunicativeMethodParamName
            # This could be more efficient and allocate less, however it *should* only be used for root spans and sanitizing invalid tracestate
            # in the most common configuration of parent_consistent_probability_based(root: consistent_probability_based(p)).
            ps = "p:#{p}" unless p.nil?
            rs = "r:#{r}" unless r.nil?
            ot = [ps, rs, rest].compact.join(';')
            tracestate.set_value('ot', ot)
          end

          def new_tracestate(p: nil, r: nil) # rubocop:disable Naming/UncommunicativeMethodParamName
            if p.nil? && r.nil?
              Tracestate.DEFAULT
            elsif p.nil?
              Tracestate.from_hash('ot' => "r:#{r}")
            elsif r.nil?
              Tracestate.from_hash('ot' => "p:#{p}")
            else
              Tracestate.from_hash('ot' => "p:#{p};r:#{r}")
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
