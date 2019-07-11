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

      def set_attribute(key, value)
        raise ArgumentError unless key.instance_of?(String) || key.instance_of?(Symbol)
        raise ArgumentError unless value.instance_of?(String) || value.instance_of?(Symbol) || value == false || value == true || value.is_a?(Numeric)
      end
      alias []= set_attribute

      def add_event(name, **attrs)
        raise ArgumentError if name.nil?
      end

      def add_link(span_context_or_link, **attrs)
        raise ArgumentError if span_context_or_link.nil?
        raise ArgumentError unless span_context_or_link.instance_of?(SpanContext) || attrs.empty?
      end

      def status=(status)
        raise ArgumentError if status.nil?
      end

      def name=(new_name)
        raise ArgumentError if new_name.nil?
      end

      def finish; end
    end
  end
end
