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

        def initialize(span)
          @span = span
          @context = SpanContext.new(span)
          @baggage = {}
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
          # if key.is_nil? || value.is_nil?
          #   return self
          # end
          # TODO: needs to be fleshed out along with span context refactor based on java implementation
        end

        def get_baggage_item(key)
          nil
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
