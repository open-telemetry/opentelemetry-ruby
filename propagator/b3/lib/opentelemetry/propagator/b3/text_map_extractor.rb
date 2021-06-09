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
    # Namespace for OpenTelemetry B3 propagation
    module B3
      # Extracts trace context using the b3 single or multi header formats, favouring b3 single header.
      module TextMapExtractor
        B3_CONTEXT_REGEX = /\A(?<trace_id>(?:[0-9a-f]{16}){1,2})-(?<span_id>[0-9a-f]{16})(?:-(?<sampling_state>[01d](?![0-9a-f])))?(?:-(?<parent_span_id>[0-9a-f]{16}))?\z/.freeze
        B3_TRACE_ID_REGEX = /\A(?:[0-9a-f]{16}){1,2}\z/.freeze
        B3_SPAN_ID_REGEX = /\A[0-9a-f]{16}\z/.freeze
        SAMPLED_VALUES = %w[1 true].freeze

        B3_CONTEXT_KEY = 'b3'
        B3_TRACE_ID_KEY = 'X-B3-TraceId'
        B3_SPAN_ID_KEY = 'X-B3-SpanId'
        B3_SAMPLED_KEY = 'X-B3-Sampled'
        B3_FLAGS_KEY = 'X-B3-Flags'

        private_constant :B3_CONTEXT_REGEX, :B3_TRACE_ID_REGEX, :B3_SPAN_ID_REGEX, :SAMPLED_VALUES
        private_constant :B3_CONTEXT_KEY, :B3_TRACE_ID_KEY, :B3_SPAN_ID_KEY, :B3_SAMPLED_KEY, :B3_FLAGS_KEY

        # Extract trace context from the supplied carrier. The b3 single header takes
        # precedence over the multi-header format.
        # If extraction fails, the original context will be returned.
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
          extract_b3_single_header(carrier, context, getter) || extract_b3_multi_header(carrier, context, getter) || context
        end

        private

        def extract_b3_single_header(carrier, context, getter)
          match = getter.get(carrier, B3_CONTEXT_KEY)&.match(B3_CONTEXT_REGEX)
          return unless match

          debug = match['sampling_state'] == 'd'
          sampled = debug || match['sampling_state'] == '1'
          extracted_context(match['trace_id'], match['span_id'], sampled, debug, context)
        end

        def extract_b3_multi_header(carrier, context, getter)
          trace_id_hex = getter.get(carrier, B3_TRACE_ID_KEY)
          return unless B3_TRACE_ID_REGEX.match?(trace_id_hex)

          span_id_hex = getter.get(carrier, B3_SPAN_ID_KEY)
          return unless B3_SPAN_ID_REGEX.match?(span_id_hex)

          sampled = getter.get(carrier, B3_SAMPLED_KEY)
          flags = getter.get(carrier, B3_FLAGS_KEY)

          debug = flags == '1'
          sampled = debug || SAMPLED_VALUES.include?(sampled)
          extracted_context(trace_id_hex, span_id_hex, sampled, debug, context)
        end

        def extracted_context(trace_id_hex, span_id_hex, sampled, debug, context)
          span_context = Trace::SpanContext.new(
            trace_id: to_trace_id(trace_id_hex),
            span_id: to_span_id(span_id_hex),
            trace_flags: to_trace_flags(sampled),
            remote: true
          )

          span = OpenTelemetry::Trace.non_recording_span(span_context)
          context = B3.context_with_debug(context) if debug
          Trace.context_with_span(span, parent_context: context)
        end

        def to_trace_flags(sampled)
          if sampled
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        # Convert an id from a hex encoded string to byte array, optionally left
        # padding to the correct length. Assumes the input id has already been
        # validated to be 16 or 32 characters in length.
        def to_trace_id(hex_id)
          if hex_id.length == 32
            Array(hex_id).pack('H*')
          else
            [0, hex_id].pack('qH*')
          end
        end

        # Convert an id from a hex encoded string to byte array.
        def to_span_id(hex_id)
          Array(hex_id).pack('H*')
        end
      end
    end
  end
end
