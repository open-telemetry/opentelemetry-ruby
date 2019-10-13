# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Span represents a single operation within a trace. Spans can be nested to
    # form a trace tree. Often, a trace contains a root span that describes the
    # end-to-end latency and, optionally, one or more sub-spans for its
    # sub-operations.
    #
    # Once Span {Tracer#start_span is created} - Span operations can be used to
    # add additional properties to it like attributes, links, events, name and
    # resulting status. Span cannot be used to retrieve these properties. This
    # prevents the mis-use of spans as an in-process information propagation
    # mechanism.
    #
    # {Span} must be ended by calling {#finish}.
    class Span
      # Retrieve the spans SpanContext
      #
      # The returned value may be used even after the Span is finished.
      #
      # @return [SpanContext]
      attr_reader :context

      # Spans must be created using {Tracer}. This is for internal use only.
      #
      # @api private
      def initialize(span_context: nil)
        @context = span_context || SpanContext.new
      end

      # Return whether this span is recording.
      #
      # @return [Boolean] true if this Span is active and recording information
      #   like events with the #add_event operation and attributes using
      #   #set_attribute.
      def recording?
        false
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
        raise ArgumentError, 'invalid key' unless Internal.valid_key?(key)
        raise ArgumentError, 'invalid value' unless Internal.valid_value?(value)

        self
      end
      alias []= set_attribute

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
      def add_event(name: nil, attributes: nil, timestamp: nil) # rubocop:disable Metrics/CyclomaticComplexity
        raise ArgumentError unless block_given? == (name.nil? && attributes.nil? && timestamp.nil?)
        raise ArgumentError unless block_given? || name.is_a?(String)
        raise ArgumentError unless Internal.valid_attributes?(attributes)

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
        raise ArgumentError unless status.is_a?(Status)
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
        raise ArgumentError if new_name.nil?
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
        self
      end

      INVALID = new(span_context: SpanContext::INVALID)
    end
  end
end
