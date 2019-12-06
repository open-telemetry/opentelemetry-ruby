# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer < OpenTelemetry::Trace::Tracer
        attr_reader :name
        attr_reader :version

        # @api private
        #
        # Returns a new {Tracer} instance.
        #
        # @param [String] name Instrumentation package name
        # @param [String] version Instrumentation package version
        #
        # @return [Tracer]
        def initialize(name, version)
          @name = name
          @version = version
          @resource = Resources::Resource.create('name' => name, 'version' => version)
        end

        def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
          parent_span_context = OpenTelemetry::Trace::SpanContext::INVALID
          start_span(name, with_parent_context: parent_span_context, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind, sampling_hint: sampling_hint)
        end

        def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
          name ||= 'empty'

          parent_span_context = with_parent&.context || with_parent_context || current_span_context
          parent_span_context = nil unless parent_span_context.valid?
          parent_span_id = parent_span_context&.span_id
          tracestate = parent_span_context&.tracestate
          trace_id = parent_span_context&.trace_id
          trace_id ||= OpenTelemetry::Trace.generate_trace_id
          span_id = OpenTelemetry::Trace.generate_span_id
          sampler = OpenTelemetry.tracer_factory.active_trace_config.sampler
          result = sampler.call(trace_id: trace_id, span_id: span_id, parent_context: parent_span_context, hint: sampling_hint, links: links, name: name, kind: kind, attributes: attributes)

          internal_create_span(result, name, kind, trace_id, span_id, parent_span_id, attributes, links, start_timestamp, tracestate)
        end

        private

        def internal_create_span(result, name, kind, trace_id, span_id, parent_span_id, attributes, links, start_timestamp, tracestate) # rubocop:disable Metrics/AbcSize
          if result.recording? && !OpenTelemetry.tracer_factory.stopped?
            trace_flags = result.sampled? ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
            context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, trace_flags: trace_flags, tracestate: tracestate)
            attributes = attributes&.merge(result.attributes) || result.attributes
            active_trace_config = OpenTelemetry.tracer_factory.active_trace_config
            active_span_processor = OpenTelemetry.tracer_factory.active_span_processor
            Span.new(context, name, kind, parent_span_id, active_trace_config, active_span_processor, attributes, links, start_timestamp || Time.now, @resource)
          else
            OpenTelemetry::Trace::Span.new(span_context: OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id))
          end
        end
      end
    end
  end
end
