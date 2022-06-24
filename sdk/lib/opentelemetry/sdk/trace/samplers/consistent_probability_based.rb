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
        # Implements consistent sampling based on a probability.
        class ConsistentProbabilityBased
          include ConsistentProbabilityTraceState

          attr_reader :description

          def initialize(probability)
            # TODO: probability should be 0 if it is < 2**-62
            @probability = probability
            @p_floor = (Math.frexp(probability)[1] - 1).abs
            @p_ceil = @p_floor + 1
            floor = Math.ldexp(1.0, -@p_floor)
            ceil = Math.ldexp(1.0, -@p_ceil)
            @p_ceil_probability = (probability - floor) / (ceil - floor)
            @description = format('ConsistentProbabilityBased{%.6f}', probability)
          end

          def ==(other)
            @description == other.description
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            parent_span_context = OpenTelemetry::Trace.current_span(parent_context).context
            if !parent_span_context.valid?
              r = generate_r(trace_id)
              p = probabilistic_p
              if p < r
                tracestate = TraceState.from_hash({ 'p' => p.to_s, 'r' => r.to_s })
                Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
              else
                tracestate = TraceState.from_hash({ 'r' => r.to_s })
                Result.new(decision: Decision::DROP, tracestate: tracestate)
              end
            else
              decision = nil
              tracestate = validate_tracestate(parent_span_context) do |ot, r|
                if r.nil?
                  # TODO: warn the user that a potentially inconsistent trace is being produced
                  r = generate_r(trace_id)
                  ot.set_value('r', r.to_s)
                end
                p = probabilistic_p
                if p < r
                  ot.set_value('p', p.to_s)
                  decision = Decision::RECORD_AND_SAMPLE
                else
                  decision = Decision::DROP
                end
                ot
              end
              Result.new(decision: decision, tracestate: tracestate)
            end
          end

          private

          def generate_r(trace_id)
            x = trace_id[8, 8].unpack1('Q>') | 0x3
            clz = 64 - x.bit_length
            clz
          end

          def probabilistic_p
            if Random.rand < @p_ceil_probability
              @p_ceil
            else
              @p_floor
            end
          end
        end
      end
    end
  end
end
