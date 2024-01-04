# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Exemplar
        class ExemplarReservoir
          def initialize
            @exemplars = []
          end

          # Store the info into exemplars bucket
          #
          # @param [Integer] value Value of the measurement
          # @param [Integer] timestamp Time of recording
          # @param [Hash] attributes Complete set of Attributes of the measurement
          # @param [Context] context SpanContext of the measurement, which covers the Baggage and the current active Span.
          #
          # @return [Nil]
          def offer(value: nil, timestamp: nil, attributes: nil, context: nil)
            span_context = current_span_context(context)
            @exemplars << Exemplar.new(value, timestamp, attributes, span_context.hex_span_id, span_context.hex_trace_id)
            nil
          end

          # return list of Exemplars based on given attributes
          #
          # @param [Hash] attributes Value of the measurement
          # @param [Boolean] aggregation_temporality Should remove the original exemplars or not, default delta
          # 
          # @return [Array] exemplars Array of exemplars
          def collect(attributes: nil, aggregation_temporality: :delta)
            exemplars = []
            @exemplars.each do |exemplar|
              exemplars << exemplar if exemplar # TODO Addition operation on selecting exemplar
            end
            @exemplars.clear if aggregation_temporality == :delta
            exemplars
          end

          def current_span_context(context)
            ::OpenTelemetry::Trace.current_span(context).context
          end
        end
      end
    end
  end
end
