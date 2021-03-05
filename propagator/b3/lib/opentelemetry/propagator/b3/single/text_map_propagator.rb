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
      # Namespace for OpenTelemetry b3 single header encoding
      module Single
        # Propagates trace context using the b3 single header format
        class TextMapPropagator
          B3_CONTEXT_REGEX = /\A(?<trace_id>(?:[0-9a-f]{16}){1,2})-(?<span_id>[0-9a-f]{16})(?:-(?<sampling_state>[01d](?![0-9a-f])))?(?:-(?<parent_span_id>[0-9a-f]{16}))?\z/.freeze
          SAMPLED_VALUES = %w[1 d].freeze
          B3_CONTEXT_KEY = 'b3'
          FIELDS = [B3_CONTEXT_KEY].freeze

          private_constant :B3_CONTEXT_REGEX, :SAMPLED_VALUES, :B3_CONTEXT_KEY, :FIELDS

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

            sampling_state = if B3.debug?(context)
                               'd'
                             elsif span_context.trace_flags.sampled?
                               '1'
                             else
                               '0'
                             end

            b3_value = "#{span_context.hex_trace_id}-#{span_context.hex_span_id}-#{sampling_state}"

            setter.set(carrier, B3_CONTEXT_KEY, b3_value)
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
            match = getter.get(carrier, B3_CONTEXT_KEY)&.match(B3_CONTEXT_REGEX)
            return context unless match

            span_context = Trace::SpanContext.new(
              trace_id: B3.to_trace_id(match['trace_id']),
              span_id: B3.to_span_id(match['span_id']),
              trace_flags: to_trace_flags(match['sampling_state']),
              remote: true
            )

            span = Trace::Span.new(span_context: span_context)
            context = B3.context_with_debug(context) if match['sampling_state'] == 'd'
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

          def to_trace_flags(sampling_state)
            if SAMPLED_VALUES.include?(sampling_state)
              Trace::TraceFlags::SAMPLED
            else
              Trace::TraceFlags::DEFAULT
            end
          end
        end
      end
    end
  end
end
