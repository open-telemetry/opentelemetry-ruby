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
        # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
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
              OpenTelemetry.logger.warn('Calling set_attribute on an ended Span.')
            else
              @attributes ||= {}
              @attributes[key] = value
              @trace_config.trim_span_attributes(@attributes)
              @total_recorded_attributes += 1
            end
          end
          self
        end

        # Add an Event to a {Span}. This can be accomplished eagerly or lazily.
        # Lazy evaluation is useful when the event attributes are expensive to
        # build and where the cost can be avoided for an unsampled {Span}.
        #
        # Eager example:
        #
        #   span.add_event(name: 'event', attributes: {'eager' => true})
        #
        # Lazy example:
        #
        #   span.add_event { tracer.create_event(name: 'event', attributes: {'eager' => false}) }
        #
        # Note that the OpenTelemetry project
        # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/semantic-conventions.md
        # documents} certain "standard event names and keys" which have
        # prescribed semantic meanings.
        #
        # @param [optional String] name Optional name of the event. This is
        #   required if a block is not given.
        # @param [optional Hash<String, Object>] attributes One or more key:value
        #   pairs, where the keys must be strings and the values may be string,
        #   boolean or numeric type. This argument should only be used when
        #   passing in a name.
        # @param [optional Time] timestamp Optional timestamp for the event.
        #   This argument should only be used when passing in a name.
        #
        # @return [self] returns itself
        def add_event(name: nil, attributes: nil, timestamp: nil)
          super
          event = block_given? ? yield : Event.new(name: name, attributes: attributes, timestamp: timestamp || Time.now)
          @mutex.synchronize do
            if @ended
              OpenTelemetry.logger.warn('Calling add_event on an ended Span.')
            else
              @events ||= []
              @events << event
              @trace_config.trim_events(@events)
              @total_recorded_events += 1
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
              OpenTelemetry.logger.warn('Calling status= on an ended Span.')
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
              OpenTelemetry.logger.warn('Calling name= on an ended Span.')
            else
              @name = new_name
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
        # This API MUST be non-blocking*.
        #
        # (*) not actually non-blocking.
        #
        # @param [Time] end_timestamp optional end timestamp for the span.
        #
        # @return [self] returns itself
        def finish(end_timestamp: nil)
          @mutex.synchronize do
            if @ended
              OpenTelemetry.logger.warn('Calling finish on an ended Span.')
              return self
            end
            @end_timestamp = end_timestamp || Time.now
            @ended = true
          end
          @span_processor.on_end(self)
          self
        end

        # TODO: return a real proto
        def to_proto
          {
            name: @name,
            kind: @kind,
            status: @status,
            parent_span_id: @parent_span_id,
            child_count: @child_count,
            total_recorded_attributes: @total_recorded_attributes,
            total_recorded_events: @total_recorded_events,
            total_recorded_links: @total_recorded_links,
            start_timestamp: @start_timestamp,
            end_timestamp: @end_timestamp,
            attributes: @attributes.freeze,
            links: @links.freeze,
            events: @events.freeze,
            span_id: context.span_id,
            trace_id: context.trace_id,
            trace_flags: context.trace_flags
          }
        end

        # @api private
        def initialize(context, name, kind, parent_span_id, trace_config, span_processor, attributes, links, events, start_timestamp) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          super(span_context: context)
          @mutex = Mutex.new
          @name = name
          @kind = kind
          @parent_span_id = parent_span_id || OpenTelemetry::Trace::INVALID_SPAN_ID
          @trace_config = trace_config
          @span_processor = span_processor
          @ended = false
          @status = nil
          @child_count = 0
          @total_recorded_events = events&.size || 0
          @total_recorded_links = links&.size || 0
          @total_recorded_attributes = attributes&.size || 0
          @start_timestamp = start_timestamp
          @end_timestamp = nil
          @attributes = attributes
          @links = links
          @events = events
          trace_config.trim_span_attributes(@attributes)
          trace_config.trim_links(@links)
          trace_config.trim_events(@events)
          @span_processor.on_start(self)
        end

        # TODO: Java implementation overrides finalize to log if a span isn't finished.
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
