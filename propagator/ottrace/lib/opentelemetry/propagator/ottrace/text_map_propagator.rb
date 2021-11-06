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
      # Propagates context using OTTrace header format
      class TextMapPropagator
        PADDING = '0' * 16
        VALID_TRACE_ID_REGEX = /^[0-9a-f]{32}$/i.freeze
        VALID_SPAN_ID_REGEX = /^[0-9a-f]{16}$/i.freeze
        TRACE_ID_64_BIT_WIDTH = 64 / 4
        TRACE_ID_HEADER = 'ot-tracer-traceid'
        SPAN_ID_HEADER = 'ot-tracer-spanid'
        SAMPLED_HEADER = 'ot-tracer-sampled'
        BAGGAGE_HEADER_PREFIX = 'ot-baggage-'
        FIELDS = [TRACE_ID_HEADER, SPAN_ID_HEADER, SAMPLED_HEADER].freeze

        # https://github.com/open-telemetry/opentelemetry-specification/blob/14d123c121b6caa53bffd011292c42a181c9ca26/specification/context/api-propagators.md#textmap-propagator0
        VALID_BAGGAGE_HEADER_NAME_CHARS = /^[\^_`a-zA-Z\-0-9!#$%&'*+.|~]+$/.freeze
        INVALID_BAGGAGE_HEADER_VALUE_CHARS = /[^\t\u0020-\u007E\u0080-\u00FF]/.freeze

        private_constant :PADDING, :VALID_TRACE_ID_REGEX, :VALID_SPAN_ID_REGEX, :TRACE_ID_64_BIT_WIDTH, :TRACE_ID_HEADER,
                         :SPAN_ID_HEADER, :SAMPLED_HEADER, :BAGGAGE_HEADER_PREFIX, :FIELDS, :VALID_BAGGAGE_HEADER_NAME_CHARS,
                         :INVALID_BAGGAGE_HEADER_VALUE_CHARS

        # Extract OTTrace context from the supplied carrier and set the active span
        # in the given context. The original context will be returned if OTTrace
        # cannot be extracted from the carrier.
        #
        # @param [Carrier] carrier The carrier to get the header from.
        # @param [optional Context] context The context to be updated with extracted context
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        # @return [Context] Updated context with active span derived from the header, or the original
        #   context if parsing fails.
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          trace_id = optionally_pad_trace_id(getter.get(carrier, TRACE_ID_HEADER))
          span_id = getter.get(carrier, SPAN_ID_HEADER)
          sampled = getter.get(carrier, SAMPLED_HEADER)

          return context unless valid?(trace_id: trace_id, span_id: span_id)

          span_context = Trace::SpanContext.new(
            trace_id: Array(trace_id).pack('H*'),
            span_id: Array(span_id).pack('H*'),
            trace_flags: as_trace_flags(sampled),
            remote: true
          )

          span = OpenTelemetry::Trace.non_recording_span(span_context)
          Trace.context_with_span(span, parent_context: set_baggage(carrier: carrier, context: context, getter: getter))
        end

        # @param [Object] carrier to update with context.
        # @param [optional Context] context The active Context.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          span_context = Trace.current_span(context).context
          return unless span_context.valid?

          inject_span_context(span_context: span_context, carrier: carrier, setter: setter)
          inject_baggage(context: context, carrier: carrier, setter: setter)

          nil
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          FIELDS
        end

        private

        def as_trace_flags(sampled)
          case sampled
          when 'true', '1'
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        def valid?(trace_id:, span_id:)
          !(VALID_TRACE_ID_REGEX !~ trace_id || VALID_SPAN_ID_REGEX !~ span_id)
        end

        def optionally_pad_trace_id(trace_id)
          if trace_id&.length == 16
            "#{PADDING}#{trace_id}"
          else
            trace_id
          end
        end

        def set_baggage(carrier:, context:, getter:)
          baggage.build(context: context) do |builder|
            prefix = BAGGAGE_HEADER_PREFIX
            getter.keys(carrier).each do |carrier_key|
              baggage_key = carrier_key.start_with?(prefix) && carrier_key[prefix.length..-1]
              next unless baggage_key
              next unless VALID_BAGGAGE_HEADER_NAME_CHARS =~ baggage_key

              value = getter.get(carrier, carrier_key)
              next unless INVALID_BAGGAGE_HEADER_VALUE_CHARS !~ value

              builder.set_value(baggage_key, value)
            end
          end
        end

        def baggage
          OpenTelemetry::Baggage
        end

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
      end
    end
  end
end
