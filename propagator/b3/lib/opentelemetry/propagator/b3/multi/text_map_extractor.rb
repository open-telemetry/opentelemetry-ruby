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
      # Namespace for OpenTelemetry b3 multi header encoding
      module Multi
        # Extracts context from carriers in the b3 single header format
        class TextMapExtractor
          B3_TRACE_ID_REGEX = /\A(?:[0-9a-f]{16}){1,2}\z/.freeze
          B3_SPAN_ID_REGEX = /\A[0-9a-f]{16}\z/.freeze
          SAMPLED_VALUES = %w[1 true].freeze
          DEBUG_FLAG = '1'
          private_constant :B3_TRACE_ID_REGEX, :B3_SPAN_ID_REGEX, :SAMPLED_VALUES, :DEBUG_FLAG

          # Returns a new TextMapExtractor that extracts b3 context using the
          # specified header keys
          #
          # @param [optional Getter] default_getter The default getter used to read
          #   headers from a carrier during extract. Defaults to a
          #   {OpenTelemetry::Context:Propagation::TextMapGetter} instance.
          # @return [TextMapExtractor]
          def initialize(default_getter = Context::Propagation.text_map_getter)
            @default_getter = default_getter
          end

          # Extract b3 context from the supplied carrier and set the active span
          # in the given context. The original context will be returned if b3
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
            getter ||= @default_getter

            trace_id_hex = getter.get(carrier, B3_TRACE_ID_KEY)
            return context unless valid_trace_id?(trace_id_hex)

            span_id_hex = getter.get(carrier, B3_SPAN_ID_KEY)
            return context unless valid_span_id?(span_id_hex)

            sampled = getter.get(carrier, B3_SAMPLED_KEY)
            flags = getter.get(carrier, B3_FLAGS_KEY)

            context = B3.context_with_debug(context) if flags == DEBUG_FLAG

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
