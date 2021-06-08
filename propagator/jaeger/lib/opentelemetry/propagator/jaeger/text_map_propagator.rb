# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

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
      # Propagates trace context using the Jaeger format
      class TextMapPropagator
        IDENTITY_KEY = 'uber-trace-id'
        DEFAULT_FLAG_BIT = 0x0
        SAMPLED_FLAG_BIT = 0x01
        DEBUG_FLAG_BIT   = 0x02
        FIELDS = [IDENTITY_KEY].freeze
        TRACE_SPAN_IDENTITY_REGEX = /\A(?<trace_id>(?:[0-9a-f]){1,32}):(?<span_id>([0-9a-f]){1,16}):[0-9a-f]{1,16}:(?<sampling_flags>[0-9a-f]{1,2})\z/.freeze
        ZERO_ID_REGEX = /^0+$/.freeze

        private_constant \
          :IDENTITY_KEY, :DEFAULT_FLAG_BIT, :SAMPLED_FLAG_BIT, :DEBUG_FLAG_BIT,
          :FIELDS, :TRACE_SPAN_IDENTITY_REGEX, :ZERO_ID_REGEX

        # Extract trace context from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [optional Context] context Context to be updated with the trace context
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   text map getter will be used.
        #
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          header = getter.get(carrier, IDENTITY_KEY)
          return context unless (match = header.match(TRACE_SPAN_IDENTITY_REGEX))
          return context if match['trace_id'] =~ ZERO_ID_REGEX
          return context if match['span_id'] =~ ZERO_ID_REGEX

          sampling_flags = match['sampling_flags'].to_i
          span = build_span(match, sampling_flags)
          context = Jaeger.context_with_debug(context) if sampling_flags & DEBUG_FLAG_BIT != 0
          context = context_with_extracted_baggage(carrier, context, getter)
          Trace.context_with_span(span, parent_context: context)
        end

        # Inject trace context into the supplied carrier.
        #
        # @param [Carrier] carrier The mutable carrier to inject trace context into
        # @param [Context] context The context to read trace context from
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   text map setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          span_context = Trace.current_span(context).context
          return unless span_context.valid?

          flags = to_jaeger_flags(context, span_context)
          trace_span_identity_value = [
            span_context.hex_trace_id, span_context.hex_span_id, '0', flags
          ].join(':')
          setter.set(carrier, IDENTITY_KEY, trace_span_identity_value)
          OpenTelemetry::Baggage.values(context: context).each do |key, value|
            baggage_key = 'uberctx-' + key
            encoded_value = CGI.escape(value)
            setter.set(carrier, baggage_key, encoded_value)
          end
          carrier
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          FIELDS
        end

        private

        def build_span(match, sampling_flags)
          trace_id = to_trace_id(match['trace_id'])
          span_context = Trace::SpanContext.new(
            trace_id: trace_id,
            span_id: to_span_id(match['span_id']),
            trace_flags: to_trace_flags(sampling_flags),
            remote: true
          )
          OpenTelemetry::Trace.non_recording_span(span_context)
        end

        def context_with_extracted_baggage(carrier, context, getter)
          baggage_key_prefix = 'uberctx-'
          OpenTelemetry::Baggage.build(context: context) do |b|
            getter.keys(carrier).each do |carrier_key|
              baggage_key = carrier_key.start_with?(baggage_key_prefix) && carrier_key[baggage_key_prefix.length..-1]
              next unless baggage_key

              raw_value = getter.get(carrier, carrier_key)
              value = CGI.unescape(raw_value)
              b.set_value(baggage_key, value)
            end
          end
        end

        def to_jaeger_flags(context, span_context)
          if span_context.trace_flags == Trace::TraceFlags::SAMPLED
            if Jaeger.debug?(context)
              SAMPLED_FLAG_BIT | DEBUG_FLAG_BIT
            else
              SAMPLED_FLAG_BIT
            end
          else
            DEFAULT_FLAG_BIT
          end
        end

        def to_trace_flags(sampling_flags)
          if (sampling_flags & SAMPLED_FLAG_BIT) != 0
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        def to_span_id(span_id_str)
          [span_id_str.rjust(16, '0')].pack('H*')
        end

        def to_trace_id(trace_id_str)
          [trace_id_str.rjust(32, '0')].pack('H*')
        end
      end
    end
  end
end
