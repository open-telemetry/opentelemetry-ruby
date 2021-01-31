# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # Injects context into carriers using the W3C Trace Context format
        class TextMapInjector
          # Returns a new TextMapInjector that injects context using the
          # specified setter
          #
          # @param [optional Setter] default_setter The default setter used to
          #   write context into a carrier during inject. Defaults to a
          #   {TextMapSetter} instance.
          # @return [TextMapInjector]
          def initialize(default_setter = Context::Propagation.text_map_setter)
            @default_setter = default_setter
          end

          # Set the span context on the supplied carrier.
          #
          # @param [Context] context The active {Context}.
          # @param [optional Setter] setter If the optional setter is provided, it
          #   will be used to write context into the carrier, otherwise the default
          #   setter will be used.
          # @return [Object] the carrier with context injected
          def inject(carrier, context, setter = nil)
            return carrier unless (span_context = span_context_from(context))

            setter ||= @default_setter
            setter.set(carrier, TRACEPARENT_KEY, TraceParent.from_span_context(span_context).to_s)
            setter.set(carrier, TRACESTATE_KEY, span_context.tracestate.to_s) unless span_context.tracestate.empty?

            carrier
          end

          private

          def span_context_from(context)
            OpenTelemetry::Trace.current_span(context).context
          end
        end
      end
    end
  end
end
