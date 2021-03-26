# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      # Injects context into carriers using the xray single header format
      class TextMapInjector
        # Returns a new TextMapInjector that injects XRay context using the
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

          sampling_state = if XRay.debug?(context)
                             'd'
                           elsif span_context.trace_flags.sampled?
                             '1'
                           else
                             '0'
                           end

          ot_trace_id = span_context.hex_trace_id
          xray_trace_id = "1-#{ot_trace_id[0..6]}-#{ot_trace_id[7..ot_trace_id.length]}"
          parent_id = span_context.hex_span_id

          xray_value = "Root=#{xray_trace_id};Parent=#{parent_id};Sampled=#{sampling_state}"

          setter ||= @default_setter
          setter.set(carrier, XRAY_CONTEXT_KEY, xray_value)
          carrier
        end
      end
    end
  end
end
