# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      # Injects context into carriers using the W3C Trace Context format
      class JobTraceContextInjector
        include Context::Propagation::DefaultSetter

        # Returns a new JobTraceContextInjector that injects context using the
        # specified header keys
        #
        # @param [String] traceparent_key The traceparent header key used in the carrier
        # @param [String] tracestate_key The tracestate header key used in the carrier
        # @return [JobTraceContextInjector]
        def initialize(
          traceparent_key: 'traceparent',
          tracestate_key: 'tracestate'
        )

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
        def inject(context, carrier, &setter)
          return carrier unless (span_context = span_context_from(context))

          setter ||= DEFAULT_SETTER
          setter.call(carrier, @traceparent_key, TraceParent.from_context(span_context).to_s)
          setter.call(carrier, @tracestate_key, span_context.tracestate) unless span_context.tracestate.nil?

          carrier
        end

        private

        def span_context_from(context)
          context[ContextKeys.current_span_key]&.context ||
            context[ContextKeys.extracted_span_context_key]
        end
      end
    end
  end
end
