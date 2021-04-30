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
          include TextMapExtractor

          FIELDS = [B3_TRACE_ID_KEY, B3_SPAN_ID_KEY, B3_SAMPLED_KEY, B3_FLAGS_KEY].freeze

          private_constant :FIELDS

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
              setter.set(carrier, B3_FLAGS_KEY, '1')
            elsif span_context.trace_flags.sampled?
              setter.set(carrier, B3_SAMPLED_KEY, '1')
            else
              setter.set(carrier, B3_SAMPLED_KEY, '0')
            end

            nil
          end

          # Returns the predefined propagation fields. If your carrier is reused, you
          # should delete the fields returned by this method before calling +inject+.
          #
          # @return [Array<String>] a list of fields that will be used by this propagator.
          def fields
            FIELDS
          end
        end
      end
    end
  end
end
