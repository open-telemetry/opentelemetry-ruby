# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      # Extracts context from carriers in the xray single header format
      class TextMapExtractor
        include Context::Propagation::DefaultGetter

        XRAY_CONTEXT_REGEX = /\ARoot=(?<trace_id>([a-z0-9\-]{35}))(?:;Parent=(?<span_id>([a-z0-9]{16})))?(?:;Sampled=(?<sampling_state>[01d](?![0-9a-f])))?\Z/.freeze
        SAMPLED_VALUES = %w[1 d].freeze

        # Returns a new TextMapExtractor that extracts xray context using the
        # specified header keys
        #
        # @param [String] xray_key The xray header key used in the carrier
        # @return [TextMapExtractor]
        def initialize(xray_key: 'X-Amzn-Trace-Id')
          @xray_key = xray_key
        end

        # Extract xray context from the supplied carrier and set the active span
        # in the given context. The original context will be returned if xray
        # cannot be extracted from the carrier.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [Context] context The context to be updated with extracted context
        # @param [optional Callable] getter An optional callable that takes a carrier and a key and
        #   returns the value associated with the key. If omitted the default getter will be used
        #   which expects the carrier to respond to [] and []=.
        # @yield [Carrier, String] if an optional getter is provided, extract will yield the carrier
        #   and the header key to the getter.
        # @return [Context] Updated context with active span derived from the header, or the original
        #   context if parsing fails.
        def extract(carrier, context, &getter)
          getter ||= default_getter
          header = getter.call(carrier, @xray_key)
          return context unless (match = header.match(XRAY_CONTEXT_REGEX))

          span_context = Trace::SpanContext.new(
            trace_id: XRay.to_trace_id(match['trace_id']),
            span_id: XRay.to_span_id(match['span_id']),
            trace_flags: to_trace_flags(match['sampling_state']),
            remote: true
          )

          span = Trace::Span.new(span_context: span_context)
          context = XRay.context_with_debug(context) if match['sampling_state'] == 'd'
          Trace.context_with_span(span, parent_context: context)
        rescue OpenTelemetry::Error
          context
        end

        private

        def to_trace_flags(sampling_state)
          if SAMPLED_VALUES.include?(sampling_state)
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end
      end
    end
  end
end
