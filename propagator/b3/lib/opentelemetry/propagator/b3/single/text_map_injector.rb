# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Propagator
    # Namespace for OpenTelemetry propagator extension libraries
    module B3
      # Namespace for OpenTelemetry b3 single header encoding
      module Single
        # Injects context into carriers using the b3 single header format
        class TextMapInjector
          include Context::Propagation::DefaultSetter

          # Returns a new TextMapInjector that extracts b3 context using the
          # specified header keys
          #
          # @param [String] b3_key The traceparent header key used in the carrier
          # @return [TextMapInjector]
          def initialize(b3_key: 'b3')
            @b3_key = b3_key
          end

          # Set the span context on the supplied carrier.
          #
          # @param [Context] context The active {Context}.
          # @param [optional Callable] setter An optional callable that takes a carrier and a key and
          #   a value and assigns the key-value pair in the carrier. If omitted the default setter
          #   will be used which expects the carrier to respond to [] and []=.
          # @yield [Carrier, String, String] if an optional setter is provided, inject will yield
          #   carrier, header key, header value to the setter.
          # @return [Object] the carrier with context injected
          def inject(carrier, context, &setter)
            span_context = Trace.current_span(context).context
            return unless span_context&.valid?

            sampling_state = if B3.debug?(context)
                               'd'
                             elsif span_context.trace_flags.sampled?
                               '1'
                             else
                               '0'
                             end

            b3_value = "#{span_context.hex_trace_id}-#{span_context.hex_span_id}-#{sampling_state}"

            setter ||= DEFAULT_SETTER
            setter.call(carrier, @b3_key, b3_value)
            carrier
          end
        end
      end
    end
  end
end
