# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
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
    # Namespace for OpenTelemetry OTTrace propagation
    module OTTrace
      # Injects context into carriers using the OTTrace format
      class TextMapInjector
        TRACE_ID_64_BIT_WIDTH = 64 / 4

        # Returns a new TextMapInjector that injects context using the specified setter
        #
        # @param [optional Setter] default_setter The default setter used to
        #   write context into a carrier during inject. Defaults to a
        #   {OpenTelemetry::Context:Propagation::TextMapSetter} instance.
        # @return [TextMapInjector]
        def initialize(default_setter: Context::Propagation.text_map_setter)
          @default_setter = default_setter
        end

        # @param [Object] carrier to update with context.
        # @param [Context] context The active Context.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, context, setter = nil)
          setter ||= default_setter
          span_context = Trace.current_span(context).context
          return unless span_context.valid?

          inject_span_context(span_context: span_context, carrier: carrier, setter: setter)
          inject_baggage(context: context, carrier: carrier, setter: setter)

          nil
        end

        private

        attr_reader :default_setter

        def inject_span_context(span_context:, carrier:, setter:)
          setter.set(carrier, TRACE_ID_HEADER, span_context.hex_trace_id[TRACE_ID_64_BIT_WIDTH, TRACE_ID_64_BIT_WIDTH])
          setter.set(carrier, SPAN_ID_HEADER, span_context.hex_span_id)
          setter.set(carrier, SAMPLED_HEADER, span_context.trace_flags.sampled?.to_s)
        end

        def inject_baggage(context:, carrier:, setter:)
          baggage.values(context: context)
                 .select { |key, value| valid_baggage_entry?(key, value) }
                 .each { |key, value| setter.set(carrier, "#{BAGGAGE_HEADER_PREFIX}#{key}", value) }
        end

        def valid_baggage_entry?(key, value)
          VALID_BAGGAGE_HEADER_NAME_CHARS =~ key && INVALID_BAGGAGE_HEADER_VALUE_CHARS !~ value
        end

        def baggage
          OpenTelemetry.baggage
        end
      end
    end
  end
end
