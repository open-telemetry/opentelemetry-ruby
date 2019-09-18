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

        # Returns a new {Tracer} instance.
        #
        # @return [Tracer]
        def initialize
          @active_span_processor = NoopSpanProcessor.instance
          @active_trace_config = Config::TraceConfig::DEFAULT
          @registered_span_processors = []
          @mutex = Mutex.new
          @stopped = false
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
            else
              @active_span_processor.shutdown
              @stopped = true
            end
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
            @registered_span_processors << span_processor
            @active_span_processor = MultiSpanProcessor.new(registered_span_processors)
          end
        end

        def start_root_span(name, attributes: nil, links: nil, events: nil, start_timestamp: nil, kind: nil)
          raise ArgumentError if name.nil?

          trace_id = OpenTelemetry::Trace.generate_trace_id
          span_id = OpenTelemetry::Trace.generate_span_id
          decision = @active_trace_config.sampler.decision(trace_id: trace_id, span_id: span_id, span_name: name, links: links)
          if decision.sampled?
            context = SpanContext.new(trace_id: trace_id, trace_flags: TraceFlags::SAMPLED)
            Span.new(context, name, kind, nil, @active_trace_config, @active_span_processor, attributes, links, events, start_timestamp || Time.now)
          else
            OpenTelemetry::Trace::Span.new(span_context: SpanContext.new(trace_id: trace_id))
          end
        end

        def start_span(name, with_parent: nil, with_parent_context: nil, attributes: nil, links: nil, events: nil, start_timestamp: nil, kind: nil)
          raise ArgumentError if name.nil?

          parent_span_context = with_parent&.context || with_parent_context || current_span.context
          if parent_span_context.valid?
            context = SpanContext.new(trace_id: parent_span_context.trace_id, trace_flags: parent_span_context.trace_flags)
            Span.new(context, name, kind, parent_span_context.span_id, @active_trace_config, @active_span_processor, attributes, links, events, start_timestamp || Time.now)
          else
            start_root_span(name, attributes: attributes, links: links, events: events, start_timestamp: start_timestamp, kind: kind)
          end
        end

        # Returns a new Event. This should be called in a block passed to
        # {Span#add_event}, or to pass Events to {Tracer#in_span},
        # {Tracer#start_span} or {Tracer#start_root_span}.
        #
        # Example use:
        #
        #   span = tracer.in_span('op', events: [tracer.create_event(name: 'e1')])
        #   span.add_event { tracer.create_event(name: 'e2', attributes: {'a' => 3}) }
        #
        # @param [String] name The name of the event.
        # @param [optional Hash<String, Object>] attributes One or more key:value
        #   pairs, where the keys must be strings and the values may be string,
        #   boolean or numeric type.
        # @param [optional Time] timestamp Optional timestamp for the event.
        # @return a new Event.
        def create_event(name:, attributes: nil, timestamp: nil)
          super
          @active_trace_config.trim_event_attributes(attributes)
          Event.new(name: name, attributes: attributes, timestamp: timestamp || Time.now)
        end

        # Returns a new Link. This should be called to pass Links to
        # {OpenTelemetry::Trace::Tracer#in_span}, {Tracer#start_span} or
        # {Tracer#start_root_span}.
        #
        # Example use:
        #
        #   span = tracer.in_span('op', links: [tracer.create_link(SpanContext.new)])
        #
        # @param [SpanContext] span_context The context of the linked {Span}.
        # @param [optional Hash<String, Object>] attrs A hash of attributes
        #   for this link. Attributes will be frozen during Link initialization.
        # @return [Link]
        def create_link(span_context, attrs = nil)
          super
          @active_trace_config.trim_link_attributes(attrs)
          Link.new(span_context: span_context, attributes: attrs)
        end
      end
    end
  end
end
