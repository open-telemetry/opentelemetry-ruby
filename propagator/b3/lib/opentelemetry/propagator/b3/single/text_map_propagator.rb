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
          include TextMapExtractor

          FIELDS = [B3_CONTEXT_KEY].freeze

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
