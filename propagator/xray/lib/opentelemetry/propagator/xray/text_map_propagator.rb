# frozen_string_literal: true

# Copyright OpenTelemetry Authors
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
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      # Propagates context in carriers in the xray single header format
      class TextMapPropagator
        XRAY_CONTEXT_KEY = 'X-Amzn-Trace-Id'
        XRAY_CONTEXT_REGEX = /\ARoot=(?<trace_id>([a-z0-9\-]{35}))(?:;Parent=(?<span_id>([a-z0-9]{16})))?(?:;Sampled=(?<sampling_state>[01d](?![0-9a-f])))?(?:;(?<trace_state>.*))?\Z/.freeze
        SAMPLED_VALUES = %w[1 d].freeze
        FIELDS = [XRAY_CONTEXT_KEY].freeze

        private_constant :XRAY_CONTEXT_KEY, :XRAY_CONTEXT_REGEX, :SAMPLED_VALUES, :FIELDS

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
          header = getter.get(carrier, XRAY_CONTEXT_KEY)
          return context unless header

          match = parse_header(header)
          return context unless match

          span_context = Trace::SpanContext.new(
            trace_id: to_trace_id(match['trace_id']),
            span_id: to_span_id(match['span_id']),
            trace_flags: to_trace_flags(match['sampling_state']),
            tracestate: to_trace_state(match['trace_state']),
            remote: true
          )

          span = OpenTelemetry::Trace.non_recording_span(span_context)
          context = XRay.context_with_debug(context) if match['sampling_state'] == 'd'
          Trace.context_with_span(span, parent_context: context)
        rescue OpenTelemetry::Error
          context
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

          sampling_state = if XRay.debug?(context)
                             'd'
                           elsif span_context.trace_flags.sampled?
                             '1'
                           else
                             '0'
                           end

          ot_trace_id = span_context.hex_trace_id
          xray_trace_id = "1-#{ot_trace_id[0..7]}-#{ot_trace_id[8..ot_trace_id.length]}"
          parent_id = span_context.hex_span_id

          xray_value = "Root=#{xray_trace_id};Parent=#{parent_id};Sampled=#{sampling_state}"

          setter.set(carrier, XRAY_CONTEXT_KEY, xray_value)
          nil
        end

        private

        def parse_header(header)
          return nil unless (match = header.match(XRAY_CONTEXT_REGEX))
          return nil unless match['trace_id']
          return nil unless match['span_id']

          match
        end

        # Convert an id from a hex encoded string to byte array. Assumes the input id has already been
        # validated to be 35 characters in length.
        def to_trace_id(hex_id)
          Array(hex_id[2..9] + hex_id[11..hex_id.length]).pack('H*')
        end

        # Convert an id from a hex encoded string to byte array.
        def to_span_id(hex_id)
          Array(hex_id).pack('H*')
        end

        def to_trace_flags(sampling_state)
          if SAMPLED_VALUES.include?(sampling_state)
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        def to_trace_state(trace_state)
          return nil unless trace_state

          Trace::Tracestate.from_string(trace_state.gsub(';', ','))
        end
      end
    end
  end
end
