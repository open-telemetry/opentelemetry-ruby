# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry B3 propagation
    module B3
      # Namespace for OpenTelemetry b3 single header encoding
      module Multi
        # Injects context into carriers using the b3 single header format
        class TextMapInjector
          # Returns a new TextMapInjector that injects b3 context using the
          # specified setter
          #
          # @param [optional Setter] default_setter The default setter used to
          #   write context into a carrier during inject. Defaults to a
          #   {OpenTelemetry::Context:Propagation::TextMapSetter} instance.
          # @return [TextMapInjector]
          def initialize(default_setter = Context::Propagation.text_map_setter)
            @default_setter = default_setter
          end

          # Set the span context on the supplied carrier.
          #
          # @param [Context] context The active Context.
          # @param [optional Setter] setter If the optional setter is provided, it
          #   will be used to write context into the carrier, otherwise the default
          #   setter will be used.
          # @return [Object] the carrier with context injected
          def inject(carrier, context, setter = nil)
            span_context = Trace.current_span(context).context
            return unless span_context.valid?

            setter ||= @default_setter
            setter.set(carrier, B3_TRACE_ID_KEY, span_context.hex_trace_id)
            setter.set(carrier, B3_SPAN_ID_KEY, span_context.hex_span_id)

            if B3.debug?(context)
              setter.set(carrier, B3_FLAGS_KEY, '1')
            elsif span_context.trace_flags.sampled?
              setter.set(carrier, B3_SAMPLED_KEY, '1')
            else
              setter.set(carrier, B3_SAMPLED_KEY, '0')
            end

            carrier
          end
        end
      end
    end
  end
end
