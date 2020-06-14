# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/sdk'
require 'opentelemetry/context/propagation'
require 'ddtrace/distributed_tracing/headers/headers'

module OpenTelemetry
  module Exporters
    module Datadog
      # Injects context into carriers using the W3C Trace Context format
      class Propagator
        include OpenTelemetry::Context::Propagation::DefaultSetter
        include OpenTelemetry::Context::Propagation::DefaultGetter

        TRACE_ID_KEY = 'x-datadog-trace-id'
        PARENT_ID_KEY = 'x-datadog-parent-id'
        SAMPLING_PRIORITY_KEY = 'x-datadog-sampling-priority'
        ORIGIN_KEY = 'x-datadog-origin'
        DD_ORIGIN = '_dd_origin'

        # Returns a new TextInjector that injects context using the
        # specified header keys
        #
        # @param [String] traceparent_key The traceparent header key used in the carrier
        # @param [String] tracestate_key The tracestate header key used in the carrier
        # @return [TextInjector]
        def initialize
          # pass
          @truncation_helper = ::Datadog::DistributedTracing::Headers::Headers.new({})
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
          return carrier unless (span_context = span_context_from(context))

          sampled = span_context.trace_flags&.sampled? ? 1 : 0
          origin = span_context.trace_state[DD_ORIGIN]
          setter ||= DEFAULT_SETTER
          setter.call(carrier, PARENT_ID_KEY, @truncation_helper.value_to_id(span_context.span_id, 16))
          setter.call(carrier, TRACE_ID_KEY, @truncation_helper.value_to_id(span_context.trace_id, 16))
          setter.call(carrier, SAMPLING_PRIORITY_KEY, sampled.to_s)
          setter.call(carrier, ORIGIN_KEY, origin)

          # setter.call(carrier, @tracestate_key, span_context.tracestate) unless span_context.tracestate.nil?

          carrier
        end

        # Extract a remote {Trace::SpanContext} from the supplied carrier.
        # Invalid headers will result in a new, valid, non-remote {Trace::SpanContext}.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [Context] context The context to be updated with extracted context
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] Updated context with span context from the header, or the original
        #   context if parsing fails.
        def extract(carrier, context, &getter)
          getter ||= default_getter
          trace_id = getter.call(carrier, TRACE_ID_KEY) || getter.call(carrier, rack_helper(TRACE_ID_KEY))
          span_id = getter.call(carrier, PARENT_ID_KEY) || getter.call(carrier, rack_helper(PARENT_ID_KEY))
          sampled = getter.call(carrier, SAMPLING_PRIORITY_KEY) || getter.call(carrier, rack_helper(SAMPLING_PRIORITY_KEY))
          origin = getter.call(carrier, ORIGIN_KEY) || getter.call(carrier, rack_helper(ORIGIN_KEY))

          is_sampled = sampled.to_i.positive? ? 1 : 0

          tracestate = origin ? "#{DD_ORIGIN}=#{origin}" : nil

          return context if trace_id.nil? || span_id.nil?

          span_context = Trace::SpanContext.new(trace_id: trace_id.to_i.to_s(16),
                                                span_id: span_id.to_i.to_s(16),
                                                trace_flags: OpenTelemetry::Trace::TraceFlags.from_byte(is_sampled),
                                                tracestate: tracestate,
                                                remote: true)

          context.set_value(Trace::Propagation::ContextKeys.extracted_span_context_key, span_context)
        rescue StandardError => e
          OpenTelemetry.logger.debug("error extracting datadog propagation, #{e.message}")
          context
        end

        private

        def rack_helper(header)
          "HTTP_#{header.to_s.upcase.gsub(/[-\s]/, '_')}"
        end

        def span_context_from(context)
          context[ContextKeys.current_span_key]&.context ||
            context[ContextKeys.extracted_span_context_key]
        end
      end
    end
  end
end
