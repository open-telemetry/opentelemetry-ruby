# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {Tracer} is the SDK implementation of {OpenTelemetry::Trace::Tracer}.
      class Tracer < OpenTelemetry::Trace::Tracer
        attr_accessor :active_trace_config
        attr_accessor :resource # TODO: should this be read-only? If not, how should exporters know when it is updated?
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
          @active_span_processor = NoopSpanProcessor.instance
          @active_trace_config = Config::TraceConfig::DEFAULT
          @registered_span_processors = []
          @mutex = Mutex.new
          @stopped = false
          @resource = Resources::Resource.create # TODO: should this initialize from env vars instead?
        end

        # Attempts to stop all the activity for this {Tracer}. Calls
        # SpanProcessor#shutdown for all registered SpanProcessors.
        #
        # This operation may block until all the Spans are processed. Must be
        # called before turning off the main application to ensure all data are
        # processed and exported.
        #
        # After this is called all the newly created {Span}s will be no-op.
        def shutdown
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#shutdown multiple times.')
              return
            end
            @active_span_processor.shutdown
            @stopped = true
          end
        end

        # Adds a new SpanProcessor to this {Tracer}.
        #
        # Any registered processor causes overhead, consider to use an
        # async/batch processor especially for span exporting, and export to
        # multiple backends using the
        # {io.opentelemetry.sdk.trace.export.MultiSpanExporter}.
        #
        # @param span_processor the new SpanProcessor to be added.
        def add_span_processor(span_processor)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#add_span_processor after shutdown.')
              return
            end
            @registered_span_processors << span_processor
            @active_span_processor = MultiSpanProcessor.new(@registered_span_processors)
          end
        end

        def start_root_span(name, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
          parent_span_context = OpenTelemetry::Trace::SpanContext::INVALID
          start_span(name, with_parent_context: parent_span_context, attributes: attributes, links: links, start_timestamp: start_timestamp, kind: kind, sampling_hint: sampling_hint)
        end

        def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, start_timestamp: nil, kind: nil, sampling_hint: nil)
          name ||= 'empty'

          parent_span_context = with_parent&.context || with_parent_context || current_span.context
          parent_span_context = nil unless parent_span_context.valid?
          parent_span_id = parent_span_context&.span_id
          trace_id = parent_span_context&.trace_id
          trace_id ||= OpenTelemetry::Trace.generate_trace_id
          span_id = OpenTelemetry::Trace.generate_span_id
          result = @active_trace_config.sampler.call(trace_id: trace_id, span_id: span_id, parent_context: parent_span_context, hint: sampling_hint, links: links, name: name, kind: kind, attributes: attributes)

          internal_create_span(result, name, kind, trace_id, span_id, parent_span_id, attributes, links, start_timestamp)
        end

        private

        def internal_create_span(result, name, kind, trace_id, span_id, parent_span_id, attributes, links, start_timestamp)
          if result.record_events? && !@stopped
            trace_flags = result.sampled? ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
            context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, trace_flags: trace_flags)
            attributes = attributes&.merge(result.attributes) || result.attributes
            Span.new(context, name, kind, parent_span_id, @active_trace_config, @active_span_processor, attributes, links, start_timestamp || Time.now)
          else
            OpenTelemetry::Trace::Span.new(span_context: OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id))
          end
        end
      end
    end
  end
end
