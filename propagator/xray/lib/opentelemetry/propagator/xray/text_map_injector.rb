# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      # Injects context into carriers using the xray single header format
      class TextMapInjector
        include Context::Propagation::DefaultSetter

        # Returns a new TextMapInjector that extracts xray context using the
        # specified header keys
        #
        # @param [String] xray_key The xray header key used in the carrier
        # @return [TextMapInjector]
        def initialize(xray_key: 'X-Amzn-Trace-Id')
          @xray_key = xray_key
        end

        # Set the span context on the supplied carrier.
        #
        # @param [Context] context The active Context.
        # @param [optional Callable] setter An optional callable that takes a carrier and a key and
        #   a value and assigns the key-value pair in the carrier. If omitted the default setter
        #   will be used which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String, String] if an optional setter is provided, inject will yield
        #   carrier, header key, header value to the setter.
        # @return [Object] the carrier with context injected
        def inject(carrier, context, &setter)
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
          xray_trace_id = '1-' + ot_trace_id[0..6] + '-' + ot_trace_id[7..ot_trace_id.length]
          parent_id = span_context.hex_span_id

          xray_value = "Root=#{xray_trace_id};Parent=#{parent_id};Sampled=#{sampling_state}"

          setter ||= default_setter
          setter.call(carrier, @xray_key, xray_value)
          carrier
        end
      end
    end
  end
end
