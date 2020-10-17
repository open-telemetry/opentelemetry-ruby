# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Propagator
    # Namespace for OpenTelemetry propagator extension libraries
    module B3
      # Namespace for OpenTelemetry b3 single header encoding
      module Multi
        # Injects context into carriers using the b3 single header format
        class TextMapInjector
          include Context::Propagation::DefaultSetter

          # Returns a new TextMapInjector that extracts b3 context using the
          # specified header keys
          #
          # @param [String] b3_trace_id_key The b3 trace id key used in the carrier
          # @param [String] b3_span_id_key The b3 span id key used in the carrier
          # @param [String] b3_sampled_key The b3 sampled key used in the carrier
          # @param [String] b3_flags_key The b3 flags key used in the carrier
          # @return [TextMapInjector]
          def initialize(b3_trace_id_key: 'X-B3-TraceId',
                         b3_span_id_key: 'X-B3-SpanId',
                         b3_sampled_key: 'X-B3-Sampled',
                         b3_flags_key: 'X-B3-Flags')
            @b3_trace_id_key = b3_trace_id_key
            @b3_span_id_key = b3_span_id_key
            @b3_sampled_key = b3_sampled_key
            @b3_flags_key = b3_flags_key
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

            setter ||= DEFAULT_SETTER
            setter.call(carrier, @b3_trace_id_key, span_context.hex_trace_id)
            setter.call(carrier, @b3_span_id_key, span_context.hex_span_id)

            if B3.debug?(context)
              setter.call(carrier, @b3_flags_key, '1')
            elsif span_context.trace_flags.sampled?
              setter.call(carrier, @b3_sampled_key, '1')
            else
              setter.call(carrier, @b3_sampled_key, '0')
            end

            carrier
          end
        end
      end
    end
  end
end
