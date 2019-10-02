# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Span provides a means of accessing an OpenTelemetry Span
      # as one would an OpenTracing span
      class Span
        DEFAULT_EVENT_NAME = 'log'

        attr_reader :span
        attr_reader :context

        def initialize(span, dist_context: nil)
          @span = span
          @context = SpanContext.new(span, dist_context: dist_context)
        end

        # Set the name of the operation
        #
        # @param [String] name
        def operation_name=(name)
          @span.name = name
        end

        # Set attribute on the underlying OpenTelemetry Span
        # @param key [String] the key of the tag
        # @param value [String, Numeric, Boolean] the value of the tag. If it's not
        # a String, Numeric, or Boolean it will be encoded with to_s
        def set_tag(key, value)
          @span.set_attribute(key, value)
          self
        end

        # Finish the underlying {Span}
        # @param end_time [Time] custom end time, if not now
        def finish(end_time: Time.now)
          @span.finish(end_timestamp: end_time)
          self
        end

        def set_baggage_item(key, value)
          return self if key.nil? || value.nil?

          @context.baggage[key] = value
        end

        def get_baggage_item(key)
          @context.baggage[key]
        end

        def log(event: nil, timestamp: Time.now, **fields)
          span.add_event(name: event, timestamp: timestamp, attributes: fields)
        end

        def log_kv(timestamp: Time.now, **fields)
          event = event_name_from_fields(fields)
          span.add_event(name: event, timestamp: timestamp, attributes: fields)
        end

        def event_name_from_fields(fields)
          return fields.fetch(:event, DEFAULT_EVENT_NAME) unless fields.nil?

          DEFAULT_EVENT_NAME
        end
      end
    end
  end
end
