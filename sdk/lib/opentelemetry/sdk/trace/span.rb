# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # Implementation of {OpenTelemetry::Trace::Span} that records trace events.
      #
      # This implementation includes reader methods intended to allow access to
      # internal state by SpanProcessors (see {NoopSpanProcessor} for the interface).
      # Instrumentation should use the API provided by {OpenTelemetry::Trace::Span}
      # and should consider {Span} to be write-only.
      #
      # rubocop:disable Metrics/ClassLength
      class Span < OpenTelemetry::Trace::Span
        # The following readers are intended for the use of SpanProcessors and
        # should not be considered part of the public interface for instrumentation.
        attr_reader :name, :status, :kind, :parent_span_id, :start_timestamp, :end_timestamp, :links, :library_resource, :instrumentation_library

        # Return a frozen copy of the current attributes. This is intended for
        # use of SpanProcesses and should not be considered part of the public
        # interface for instrumentation.
        #
        # @return [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] may be nil.
        def attributes
          # Don't bother synchronizing. Access by SpanProcessors is expected to
          # be serialized.
          @attributes&.clone.freeze
        end

        # Return a frozen copy of the current events. This is intended for use
        # of SpanProcessors and should not be considered part of the public
        # interface for instrumentation.
        #
        # @return [Array<Event>] may be nil.
        def events
          # Don't bother synchronizing. Access by SpanProcessors is expected to
          # be serialized.
          @events&.clone.freeze
        end

        # Return the flag whether this span is recording events
        #
        # @return [Boolean] true if this Span is active and recording information
        #   like events with the #add_event operation and attributes using
        #   #set_attribute.
        def recording?
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
              trim_span_attributes(@attributes)
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
        #   span.add_event { OpenTelemetry::Trace::Event.new(name: 'event', attributes: {'eager' => false}) }
        #
        # Note that the OpenTelemetry project
        # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
        # documents} certain "standard event names and keys" which have
        # prescribed semantic meanings.
        #
        # @param [optional String] name Optional name of the event. This is
        #   required if a block is not given.
        # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
        #   One or more key:value pairs, where the keys must be strings and the
        #   values may be string, boolean or numeric type. This argument should
        #   only be used when passing in a name.
        # @param [optional Time] timestamp Optional timestamp for the event.
        #   This argument should only be used when passing in a name.
        #
        # @return [self] returns itself
        def add_event(name: nil, attributes: nil, timestamp: nil)
          super
          event = block_given? ? yield : OpenTelemetry::Trace::Event.new(name: name, attributes: attributes, timestamp: timestamp || Time.now)

          @mutex.synchronize do
            if @ended
              OpenTelemetry.logger.warn('Calling add_event on an ended Span.')
            else
              @events ||= []
              @events = append_event(@events, event)
              @total_recorded_events += 1
            end
          end
          self
        end

        # Record an error during the execution of this span. Multiple errors
        # can be recorded on a span.
        #
        # @param [Exception] error The error to be recorded
        #
        # @return [void]
        def record_error(error)
          add_event(name: 'error',
                    attributes: {
                      'error.type' => error.class.to_s,
                      'error.message' => error.message,
                      'error.stack' => error.backtrace.join("\n")
                    })
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
        # (*) not actually non-blocking. In particular, it synchronizes on an
        # internal mutex, which will typically be uncontended, and
        # {Export::BatchSpanProcessor} will also synchronize on a mutex, if that
        # processor is used.
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
            @attributes.freeze
            @events.freeze
            @ended = true
          end
          @span_processor.on_finish(self)
          self
        end

        # @api private
        #
        # Returns a SpanData containing a snapshot of the Span fields. It is
        # assumed that the Span has been finished, and that no further
        # modifications will be made to the Span.
        #
        # This method should be called *only* from a SpanProcessor prior to
        # calling the SpanExporter.
        #
        # @return [SpanData]
        def to_span_data
          SpanData.new(
            @name,
            @kind,
            @status,
            @parent_span_id,
            @child_count,
            @total_recorded_attributes,
            @total_recorded_events,
            @total_recorded_links,
            @start_timestamp,
            @end_timestamp,
            @attributes,
            @links,
            @events,
            @library_resource,
            @instrumentation_library,
            context.span_id,
            context.trace_id,
            context.trace_flags,
            context.tracestate
          )
        end

        # @api private
        def initialize(context, name, kind, parent_span_id, trace_config, span_processor, attributes, links, start_timestamp, library_resource, instrumentation_library) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          super(span_context: context)
          @mutex = Mutex.new
          @name = name
          @kind = kind
          @parent_span_id = parent_span_id.freeze || OpenTelemetry::Trace::INVALID_SPAN_ID
          @trace_config = trace_config
          @span_processor = span_processor
          @library_resource = library_resource
          @instrumentation_library = instrumentation_library
          @ended = false
          @status = nil
          @child_count = 0
          @total_recorded_events = 0
          @total_recorded_links = links&.size || 0
          @total_recorded_attributes = attributes&.size || 0
          @start_timestamp = start_timestamp
          @end_timestamp = nil
          @attributes = attributes.nil? ? nil : Hash[attributes] # We need a mutable copy of attributes.
          trim_span_attributes(@attributes)
          @events = nil
          @links = trim_links(links, trace_config.max_links_count, trace_config.max_attributes_per_link)
          @span_processor.on_start(self)
        end

        # TODO: Java implementation overrides finalize to log if a span isn't finished.

        private

        def trim_span_attributes(attrs)
          return if attrs.nil?

          excess = attrs.size - @trace_config.max_attributes_count
          # TODO: with Ruby 2.5, replace with the more efficient
          # attrs.shift(excess) if excess.positive?
          excess.times { attrs.shift } if excess.positive?
          nil
        end

        def trim_links(links, max_links_count, max_attributes_per_link) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          # Fast path (likely) common cases.
          return nil if links.nil?

          if links.size <= max_links_count &&
             links.all? { |link| link.attributes.size <= max_attributes_per_link && Internal.valid_attributes?(link.attributes) }
            return links.frozen? ? links : links.clone.freeze
          end

          # Slow path: trim attributes for each Link.
          links.last(max_links_count).map! do |link|
            attrs = Hash[link.attributes] # link.attributes is frozen, so we need an unfrozen copy to adjust.
            attrs.keep_if { |key, value| Internal.valid_key?(key) && Internal.valid_value?(value) }
            excess = attrs.size - max_attributes_per_link
            excess.times { attrs.shift } if excess.positive?
            OpenTelemetry::Trace::Link.new(link.context, attrs)
          end.freeze
        end

        def append_event(events, event) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          max_events_count = @trace_config.max_events_count
          max_attributes_per_event = @trace_config.max_attributes_per_event

          # Fast path (likely) common case.
          if events.size < max_events_count &&
             event.attributes.size <= max_attributes_per_event &&
             Internal.valid_attributes?(event.attributes)
            return events << event
          end

          # Slow path.
          excess = events.size + 1 - max_events_count
          events.shift(excess) if excess.positive?

          excess = event.attributes.size - max_attributes_per_event
          if excess.positive? || !Internal.valid_attributes?(event.attributes)
            attrs = Hash[event.attributes] # event.attributes is frozen, so we need an unfrozen copy to adjust.
            attrs.keep_if { |key, value| Internal.valid_key?(key) && Internal.valid_value?(value) }
            excess = attrs.size - max_attributes_per_event
            excess.times { attrs.shift } if excess.positive?
            event = OpenTelemetry::Trace::Event.new(name: event.name, attributes: attrs, timestamp: event.timestamp)
          end
          events << event
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
