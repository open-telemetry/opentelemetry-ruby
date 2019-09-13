# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # Implementation of {OpenTelemetry::Trace::Span} that records trace events.
      #
      # rubocop:disable Metrics/ClassLength
      class Span < OpenTelemetry::Trace::Span
        # TODO: does this need synchronization? I don't think so...
        attr_reader :name

        # Return the flag whether this span is recording events
        #
        # @return [Boolean] true if this Span is active and recording information
        #   like events with the #add_event operation and attributes using
        #   #set_attribute.
        def recording_events?
          true
        end

        # Set attribute
        #
        # Note that the OpenTelemetry project
        # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/semantic-conventions.md
        # documents} certain "standard attributes" that have prescribed semantic
        # meanings.
        #
        # @param [String] key
        # @param [String, Boolean, Numeric] value
        #
        # @return [self] returns itself
        def set_attribute(key, value)
          super
          @mutex.synchronize do
            if @ended
              logger.debug('Calling set_attribute on an ended Span.')
            else
              @attributes ||= {}
              @attributes[key] = value
              trace_config.trim_attributes(@attributes, :max_attributes_count)
              @total_recorded_attributes += 1
            end
          end
          self
        end

        # Add an Event to Span
        #
        # Note that the OpenTelemetry project
        # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/semantic-conventions.md
        # documents} certain "standard event names and keys" which have
        # prescribed semantic meanings.
        #
        # @param [String, Callable] name_or_event_formatter The name of the event
        #   or an EventFormatter, a lazily evaluated callable that returns an
        #   Event instance.
        # @param [optional Hash<String, Object>] attrs One or more key:value pairs, where
        #   the keys must be strings and the values may be string, boolean or
        #   numeric type. This argument should only be used when passing in a
        #   name, not an EventFormatter.
        # @param [Time] timestamp optional timestamp for the event.
        #
        # @return [self] returns itself
        def add_event(name_or_event_formatter, attrs = nil, timestamp: nil)
          super
          timed_event =
            if name_or_event_formatter.instance_of?(String)
              TimedEvent.new(name_or_event_formatter, attrs, timestamp || Time.now)
            else
              name_or_event_formatter.call
            end
          @mutex.synchronize do
            if @ended
              logger.debug('Calling add_event on an ended Span.')
            else
              @events ||= []
              @events << timed_event
              @events.shift if @events.size > trace_config.max_events_count
              @total_recorded_events += 1
            end
          end
          self
        end

        # Adds a link to another Span from this Span. The linked Span can be from
        # the same or different trace. See {OpenTelemetry::Trace::Link} for a description.
        #
        # @param [SpanContext, Callable] span_context_or_link_formatter The
        #   SpanContext context of the Span to link with this Span or a
        #   LinkFormatter, a lazily evaluated callable that returns a Link
        #   instance.
        # @param [optional Hash<String, Object>] attrs Map of attributes associated with
        #   this link. Attributes are key:value pairs where key is a string and
        #   value is one of string, boolean or numeric type. This argument should
        #   only be used when passing in a SpanContext, not a LinkFormatter.
        #
        # @return [self] returns itself
        def add_link(span_context_or_link_formatter, attrs = nil)
          super
          link =
            if span_context_or_link_formatter.instance_of?(SpanContext)
              OpenTelemetry::Trace::Link.new(span_context_or_link_formatter, attrs)
            else
              span_context_or_link_formatter.call
            end
          @mutex.synchronize do
            if @ended
              logger.debug('Calling add_link on an ended Span.')
            else
              @links ||= []
              @links << link
              @links.shift if @links.size > trace_config.max_links_count
              @total_recorded_links += 1
            end
          end
          self
        end

        # Sets the Status to the Span
        #
        # If used, this will override the default Span status. Default is OK.
        #
        # Only the value of the last call will be recorded, and implementations
        # are free to ignore previous calls.
        #
        # @param [Status] status The new status, which overrides the default Span
        #   status, which is OK.
        #
        # @return [void]
        def status=(status)
          super
          @mutex.synchronize do
            if @ended
              logger.debug('Calling status= on an ended Span.')
            else
              @status = status
            end
          end
        end

        # Updates the Span name
        #
        # Upon this update, any sampling behavior based on Span name will depend
        # on the implementation.
        #
        # @param [String] new_name The new operation name, which supersedes
        #   whatever was passed in when the Span was started
        #
        # @return [void]
        def name=(new_name)
          super
          @mutex.synchronize do
            if @ended
              logger.debug('Calling name= on an ended Span.')
            else
              @name = name
            end
          end
        end

        # Finishes the Span
        #
        # Implementations MUST ignore all subsequent calls to {#finish} (there
        # might be exceptions when Tracer is streaming event and has no mutable
        # state associated with the Span).
        #
        # Call to {#finish} MUST not have any effects on child spans. Those may
        # still be running and can be ended later.
        #
        # This API MUST be non-blocking.
        #
        # @param [Time] end_timestamp optional end timestamp for the span.
        #
        # @return [self] returns itself
        def finish(end_timestamp: nil)
          @mutex.synchronize do
            if @ended
              logger.debug('Calling finish on an ended Span.')
            else
              @end_timestamp = end_timestamp || Time.now
              @ended = true
            end
          end
          @span_processor.on_end(self)
          self
        end

        # TODO: to_proto

        # @api private
        def initialize(context, name, kind, parent_span_id, trace_config, span_processor, attributes)
          super(span_context: context)
          @mutex = Mutex.new
          @name = name
          @kind = kind
          @parent_span_id = parent_span_id
          @trace_config = trace_config
          @span_processor = span_processor
          @ended = false
          @child_count = 0
          @total_recorded_events = 0
          @total_recorded_links = 0
          @total_recorded_attributes = attributes&.size || 0
          @start_timestamp = Time.now
          @attributes = attributes
          trace_config.trim_attributes(@attributes, :max_attributes_count)
          @span_processor.on_start(self)
        end

        # TODO: Java implementation overrides finalize to log if a span isn't finished.
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
