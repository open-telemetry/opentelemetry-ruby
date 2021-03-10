# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
#
module OpenTelemetry
  module Propagator
    module OTTrace
      class TextMapExtractor
        PADDING = '0' * 16
        VALID_TRACE_ID_REGEX = /^[0-9a-f]{32}$/.freeze
        VALID_SPAN_ID_REGEX = /^[0-9a-f]{16}$/.freeze

        # Returns a new TextMapExtractor that extracts OTTrace context using the
        # specified getter
        #
        # @param [optional Getter] default_getter The default getter used to read
        #   headers from a carrier during extract. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapGetter} instance.
        # @return [TextMapExtractor]
        def initialize(
          baggage_manager:,
          default_getter: Context::Propagation.text_map_getter
        )
          @baggage_manager = baggage_manager
          @default_getter = default_getter
        end

        # Extract OTTrace context from the supplied carrier and set the active span
        # in the given context. The original context will be returned if OTTrace
        # cannot be extracted from the carrier.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [Context] context The context to be updated with extracted context
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        # @return [Context] Updated context with active span derived from the header, or the original
        #   context if parsing fails.
        def extract(carrier, context, getter = nil)
          getter ||= default_getter
          trace_id = getter.get(carrier, TRACE_ID_HEADER)
          span_id = getter.get(carrier, SPAN_ID_HEADER)
          sampled = getter.get(carrier, SAMPLED_HEADER)

          return context unless trace_id && span_id

          trace_id = optionally_pad_trace_id(trace_id)

          return context if valid?(trace_id: trace_id, span_id: span_id)

          span_context = Trace::SpanContext.new(
            trace_id: Array(trace_id).pack('H*'),
            span_id: Array(span_id).pack('H*'),
            trace_flags: sampled == 'true' ? TraceFlags::SAMPLED : TraceFlags::DEFAULT,
            remote: true
          )

          span = Trace::Span.new(span_context: span_context)
          Trace.context_with_span(span, parent_context: set_baggage(carrier: carrier, context: context, getter: getter))
        end

        private

        attr_reader :default_getter
        attr_reader :baggage_manager

        def valid?(trace_id:, span_id:)
          VALID_TRACE_ID_REGEX !~ trace_id || VALID_SPAN_ID_REGEX !~ span_id
        end

        def optionally_pad_trace_id(trace_id)
          if trace_id.length == 16
            "#{PADDING}#{trace_id}"
          else
            trace_id
          end
        end

        def set_baggage(carrier:, context:, getter:)
          baggage_manager.build(context: context) do |builder|
            prefix = OTTrace::BAGGAGE_HEADER_PREFIX
            getter.keys(carrier).each do |carrier_key|
              baggage_key = carrier_key.start_with?(prefix) && carrier_key[prefix.length..-1]
              next unless baggage_key
              next unless VALID_BAGGAGE_HEADER_NAME_CHARS =~ baggage_key

              value = getter.get(carrier, carrier_key)
              next unless INVALID_BAGGAGE_HEADER_VALUE_CHARS !~ value

              builder.set_value(baggage_key, value)
            end
          end
        end
      end
    end
  end
end
