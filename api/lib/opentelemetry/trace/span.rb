# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Span is a mutable object storing information about the current operation execution.
    class Span
      attr_reader :context

      def initialize(span_context: nil)
        @context = span_context || SpanContext.new
      end

      def recording_events?
        false
      end

      # TODO: API suggests set_attribute(key:, value:), but this feels more idiomatic?
      def []=(key, value)
        check_not_nil(key, 'key')
        check_not_nil(value, 'value')
      end

      def add_event(name, **attrs)
        check_not_nil(name, 'name')
      end

      def add_link(span_context_or_link, **attrs)
        check_not_nil(span_context_or_link, 'span_context_or_link')
        check_empty(attrs, 'attrs') unless span_context_or_link.instance_of?(SpanContext)
      end

      def status=(status)
        check_not_nil(status, 'status')
      end

      def name=(new_name)
        check_not_nil(new_name, 'new_name')
      end

      def end; end
    end
  end
end
