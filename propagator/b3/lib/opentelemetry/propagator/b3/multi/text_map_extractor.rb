# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  module Propagator
    # Namespace for OpenTelemetry propagator extension libraries
    module B3
      # Namespace for OpenTelemetry b3 multi header encoding
      module Multi
        # Extracts context from carriers in the b3 single header format
        class TextMapExtractor
          include Context::Propagation::DefaultGetter

          B3_TRACE_ID_REGEX = /\A(?:[0-9a-f]{16}){1,2}\z/.freeze
          B3_SPAN_ID_REGEX = /\A[0-9a-f]{16}\z/.freeze
          SAMPLED_VALUES = %w[1 true].freeze
          DEBUG_FLAG = '1'

          # Returns a new TextMapExtractor that extracts b3 context using the
          # specified header keys
          #
          # @param [String] b3_trace_id_key The b3 trace id key used in the carrier
          # @param [String] b3_span_id_key The b3 span id key used in the carrier
          # @param [String] b3_sampled_key The b3 sampled key used in the carrier
          # @param [String] b3_flags_key The b3 flags key used in the carrier
          # @return [TextMapExtractor]
          def initialize(b3_trace_id_key: 'X-B3-TraceId',
                         b3_span_id_key: 'X-B3-SpanId',
                         b3_sampled_key: 'X-B3-Sampled',
                         b3_flags_key: 'X-B3-Flags')
            @b3_trace_id_key = b3_trace_id_key
            @b3_span_id_key = b3_span_id_key
            @b3_sampled_key = b3_sampled_key
            @b3_flags_key = b3_flags_key
          end

          # Extract b3 context from the supplied carrier and set the active span
          # in the given context. The original context will be returned if b3
          # cannot be extracted from the carrier.
          #
          # @param [Carrier] carrier The carrier to get the header from.
          # @param [Context] context The context to be updated with extracted context
          # @param [optional Callable] getter An optional callable that takes a carrier and a key and
          #   returns the value associated with the key. If omitted the default getter will be used
          #   which expects the carrier to respond to [] and []=.
          # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
          #   and the header key to the getter.
          # @return [Context] Updated context with active span derived from the header, or the original
          #   context if parsing fails.
          def extract(carrier, context, &getter)
            getter ||= default_getter

            trace_id_hex = getter.call(carrier, @b3_trace_id_key)
            return context unless valid_trace_id?(trace_id_hex)

            span_id_hex = getter.call(carrier, @b3_span_id_key)
            return context unless valid_span_id?(span_id_hex)

            sampled = getter.call(carrier, @b3_sampled_key)
            flags = getter.call(carrier, @b3_flags_key)

            context = B3.debug(context) if flags == DEBUG_FLAG

            span_context = Trace::SpanContext.new(
              trace_id: B3.to_trace_id(trace_id_hex),
              span_id: B3.to_span_id(span_id_hex),
              trace_flags: to_trace_flags(sampled, flags),
              remote: true
            )

            span = Trace::Span.new(span_context: span_context)
            Trace.context_with_span(span, parent_context: context)
          rescue OpenTelemetry::Error
            context
          end

          private

          def to_trace_flags(sampled, b3_flags)
            if b3_flags == DEBUG_FLAG || SAMPLED_VALUES.include?(sampled)
              Trace::TraceFlags::SAMPLED
            else
              Trace::TraceFlags::DEFAULT
            end
          end

          def valid_trace_id?(trace_id)
            B3_TRACE_ID_REGEX.match?(trace_id)
          end

          def valid_span_id?(span_id)
            B3_SPAN_ID_REGEX.match?(span_id)
          end
        end
      end
    end
  end
end
