# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # Propagates trace response using the W3C Trace Context format
        # https://w3c.github.io/trace-context/#traceresponse-header
        class ResponseTextMapPropagator
          TRACERESPONSE_KEY = 'traceresponse'
          FIELDS = [TRACERESPONSE_KEY].freeze

          private_constant :TRACERESPONSE_KEY, :FIELDS

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

            setter.set(carrier, TRACERESPONSE_KEY, TraceParent.from_span_context(span_context).to_s)
            nil
          end

          # Extract trace context from the supplied carrier. This is a no-op for
          # this propagator, and will return the provided context.
          #
          # @param [Carrier] carrier The carrier to get the header from
          # @param [optional Context] context Context to be updated with the trace context
          #   extracted from the carrier. Defaults to +Context.current+.
          # @param [optional Getter] getter If the optional getter is provided, it
          #   will be used to read the header from the carrier, otherwise the default
          #   text map getter will be used.
          #
          # @return [Context] the original context.
          def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
            context
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
