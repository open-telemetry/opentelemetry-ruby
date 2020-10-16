# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # Injects context into carriers using the W3C Trace Context format
        class TextMapInjector
          include Context::Propagation::DefaultSetter

          # Returns a new TextMapInjector that injects context using the
          # specified header keys
          #
          # @param [String] traceparent_key The traceparent header key used in the carrier
          # @param [String] tracestate_key The tracestate header key used in the carrier
          # @return [TextMapInjector]
          def initialize(traceparent_key: 'traceparent',
                         tracestate_key: 'tracestate')
            @traceparent_key = traceparent_key
            @tracestate_key = tracestate_key
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
            return carrier unless (span_reference = span_reference_from(context)).valid?

            setter ||= DEFAULT_SETTER
            setter.call(carrier, @traceparent_key, TraceParent.from_span_reference(span_reference).to_s)
            setter.call(carrier, @tracestate_key, span_reference.tracestate) unless span_reference.tracestate.nil?

            carrier
          end

          private

          def span_reference_from(context)
            OpenTelemetry::Trace.current_span(context).reference
          end
        end
      end
    end
  end
end
