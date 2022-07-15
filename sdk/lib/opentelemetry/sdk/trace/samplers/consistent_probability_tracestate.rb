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
            return yield(nil, nil, nil) if ot.nil? || ot.length > MAX_LIST_LENGTH

            p = r = nil
            rest = +''
            ot.split(';').each do |field|
              k, v = field.split(':', 2)
              # TODO: "the used keys MUST be unique." - do we need to validate this?
              case k
              when 'p' then p = decimal(v)
              when 'r' then r = decimal(v)
              else
                rest << ';' if rest.length > 0
                rest << field
              end
            end
            yield(p, r, rest)
          end

          def update_tracestate(tracestate, p, r, rest)
            s = +''
            s << "p:#{p}" if !p.nil?
            s << ';' if !p.nil? && !r.nil?
            s << "r:#{r}" if !r.nil?
            s << ';' if (!p.nil? || !r.nil?) && !rest.nil?
            s << rest if !rest.nil?
            tracestate.set_value('ot', to_s)
          end

          def new_tracestate(p: nil, r: nil)
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
