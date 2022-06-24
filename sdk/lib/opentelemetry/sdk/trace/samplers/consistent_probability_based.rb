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
          attr_reader :description

          def initialize(probability)
            @probability = probability
            @id_upper_bound = (probability * (2**64 - 1)).ceil
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
              p = y_u_pp?
              if p < r
                tracestate = TraceState.from_hash({ 'p' => p.to_s, 'r' => r.to_s })
                Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
              else
                tracestate = TraceState.from_hash({ 'r' => r.to_s })
                Result.new(decision: Decision::DROP, tracestate: tracestate)
              end
            else
              # TODO: halp!
              tracestate = parent_span_context.tracestate
            end
          end

          private

          def sample?(trace_id)
            @probability == 1.0 || trace_id[8, 8].unpack1('Q>') < @id_upper_bound
          end

          def generate_r(trace_id)
            i = 8
            trace_id.each_byte do |b|
              return i - (b&3).bit_length if i == 64
              return i - b.bit_length unless b.zero?
              i = i + 8
            end
          end

          def y_u_pp?
            # TODO: support probabilities that are not exact powers of two.
            # To do so, implementations are required to select between the
            # nearest powers of two probabilistically. For example, 5% sampling
            # can be achieved by selecting 1/16 sampling 60% of the time and
            # 1/32 sampling 40% of the time.
          end
        end
      end
    end
  end
end
