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
      # Namespace for OpenTelemetry B3 multi header encoding
      module Multi
        # Propagates trace context using the B3 multi header format
        class TextMapPropagator
          B3_TRACE_ID_REGEX = /\A(?:[0-9a-f]{16}){1,2}\z/.freeze
          B3_SPAN_ID_REGEX = /\A[0-9a-f]{16}\z/.freeze
          SAMPLED_VALUES = %w[1 true].freeze
          DEBUG_FLAG = '1'
          B3_TRACE_ID_KEY = 'X-B3-TraceId'
          B3_SPAN_ID_KEY = 'X-B3-SpanId'
          B3_SAMPLED_KEY = 'X-B3-Sampled'
          B3_FLAGS_KEY = 'X-B3-Flags'
          FIELDS = [B3_TRACE_ID_KEY, B3_SPAN_ID_KEY, B3_SAMPLED_KEY, B3_FLAGS_KEY].freeze

          private_constant :B3_TRACE_ID_REGEX, :B3_SPAN_ID_REGEX, :SAMPLED_VALUES, :DEBUG_FLAG,
                           :B3_TRACE_ID_KEY, :B3_SPAN_ID_KEY, :B3_SAMPLED_KEY, :B3_FLAGS_KEY,
                           :FIELDS

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

            setter.set(carrier, B3_TRACE_ID_KEY, span_context.hex_trace_id)
            setter.set(carrier, B3_SPAN_ID_KEY, span_context.hex_span_id)

            if B3.debug?(context)
              setter.set(carrier, B3_FLAGS_KEY, DEBUG_FLAG)
            elsif span_context.trace_flags.sampled?
              setter.set(carrier, B3_SAMPLED_KEY, '1')
            else
              setter.set(carrier, B3_SAMPLED_KEY, '0')
            end

            nil
          end

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

          # Returns the predefined propagation fields. If your carrier is reused, you
          # should delete the fields returned by this method before calling +inject+.
          #
          # @return [Array<String>] a list of fields that will be used by this propagator.
          def fields
            FIELDS
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
