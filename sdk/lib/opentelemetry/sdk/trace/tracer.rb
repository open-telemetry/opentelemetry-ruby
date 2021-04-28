# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer < OpenTelemetry::Trace::Tracer
        attr_reader :name
        attr_reader :version
        attr_reader :tracer_provider

        # @api private
        #
        # Returns a new {Tracer} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        # @param [TracerProvider] tracer_provider TracerProvider that initialized the tracer
        #
        # @return [Tracer]
        def initialize(name, version, tracer_provider)
          @name = name
          @version = version
          @instrumentation_library = InstrumentationLibrary.new(name, version)
          @tracer_provider = tracer_provider
        end

        def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          start_span(name, with_parent: Context.empty, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind)
        end

        def start_span(name, with_parent: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil)
          name ||= 'empty'

          with_parent ||= Context.current
          parent_span_context = OpenTelemetry::Trace.current_span(with_parent).context
          if parent_span_context.valid?
            parent_span_id = parent_span_context.span_id
            trace_id = parent_span_context.trace_id
          end
          trace_id ||= tracer_provider.id_generator.generate_trace_id
          sampler = tracer_provider.active_trace_config.sampler
          result = sampler.should_sample?(trace_id: trace_id, parent_context: with_parent, links: links, name: name, kind: kind, attributes: attributes)
          internal_create_span(result, name, kind, trace_id, parent_span_id, attributes, links, start_timestamp, with_parent)
        end

        private

        def internal_create_span(result, name, kind, trace_id, parent_span_id, attributes, links, start_timestamp, parent_context) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          span_id = tracer_provider.id_generator.generate_span_id
          if result.recording? && !tracer_provider.stopped?
            trace_flags = result.sampled? ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
            context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id, trace_flags: trace_flags, tracestate: result.tracestate)
            attributes = attributes&.merge(result.attributes) || result.attributes
            Span.new(
              context,
              parent_context,
              name,
              kind,
              parent_span_id,
              tracer_provider.active_trace_config,
              tracer_provider.active_span_processor,
              attributes,
              links,
              start_timestamp,
              tracer_provider.resource,
              @instrumentation_library
            )
          else
            OpenTelemetry::Trace::Span.new(span_context: OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id, tracestate: result.tracestate))
          end
        end
      end
    end
  end
end
