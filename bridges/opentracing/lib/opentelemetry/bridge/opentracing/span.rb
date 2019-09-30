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

        # The following have no OpenTelemetry Equivalent and are left noop
        def set_baggage_item(key, value)
          self
        end

        def get_baggage_item(key)
          nil
        end

        def log(event: nil, timestamp: Time.now, **fields)
          nil
        end

        def log_kv(timestamp: Time.now, **fields)
          nil
        end
      end
    end
  end
end
