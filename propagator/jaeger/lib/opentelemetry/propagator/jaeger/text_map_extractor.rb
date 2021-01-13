# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry Jaeger propagation
    module Jaeger
      # Extracts context from carriers
      class TextMapExtractor
        TRACE_SPAN_IDENTITY_REGEX = /\A(?<trace_id>(?:[0-9a-f]{16}){1,2}):(?<span_id>[0-9a-f]{16}):[0-9a-f]{1,16}:(?<sampling_flags>[0-9a-f]{1,2})\z/.freeze
        SAMPLED_VALUES = %w[1 3 5 7].freeze
        DEBUG_VALUES = %w[2 3 6 7].freeze

        # Returns a new TextMapExtractor that extracts Jaeger context using the
        # specified header keys
        #
        # @param [optional Getter] default_getter The default getter used to read
        #   headers from a carrier during extract. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapGetter} instance.
        # @return [TextMapExtractor]
        def initialize(default_getter = Context::Propagation.text_map_getter)
          @default_getter = default_getter
        end

        # Extract Jaeger context from the supplied carrier and set the active
        # span in the given context. The original context will be return if
        # Jaeger cannot be extracted from the carrier.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [Context] context The context to be updated with extracted
        #   context
        # @param [optional Callable] getter An optional callable that takes a
        #   carrier and a key and returns the value associated with the key. If
        #   omitted the default getter will be used which expects the carrier to
        #   respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract
        #   will yield the carrier and the header key to the getter.
        # @return [Context] Updated context with active span derived from the
        #   header, or the original context if parsing fails.
        def extract(carrier, context, getter = nil)
          getter ||= @default_getter
          header = getter.get(carrier, IDENTITY_KEY)
          return context unless (match = header.match(TRACE_SPAN_IDENTITY_REGEX))

          span = build_span(match)
          context = Jaeger.context_with_debug(context) if DEBUG_VALUES.include?(match['sampling_flags'])
          context = set_baggage(carrier, context, getter)
          Trace.context_with_span(span, parent_context: context)
        end

        private

        def build_span(match)
          trace_id = to_trace_id(match['trace_id'])
          span_context = Trace::SpanContext.new(
            trace_id: trace_id,
            span_id: Array(match['span_id']).pack('H*'),
            trace_flags: to_trace_flags(match['sampling_flags']),
            remote: true
          )
          Trace::Span.new(span_context: span_context)
        end

        def set_baggage(carrier, context, getter)
          getter.keys(carrier).each do |carrier_key|
            baggage_key = (carrier_key =~ /^uberctx-(.*)/) && Regexp.last_match(1).downcase.gsub(/_/, '-')
            next unless baggage_key

            value = getter.get(carrier, carrier_key)
            context = OpenTelemetry.baggage.set_value(
              baggage_key, value, context: context
            )
          end
          context
        end

        def to_trace_flags(sampling_flags)
          if SAMPLED_VALUES.include?(sampling_flags)
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        def to_trace_id(trace_id_str)
          if trace_id_str.length == 32
            Array(trace_id_str).pack('H*')
          else
            [0, trace_id_str].pack('qH*')
          end
        end
      end
    end
  end
end
