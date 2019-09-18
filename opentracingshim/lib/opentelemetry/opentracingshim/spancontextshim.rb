# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class SpanContextShim < OpenTracing::SpanContext
      attr_reader :context

      def initialize(context)
        @context = context
      end

      def trace_id
        context.trace_id
      end

      def span_id
        context.span_id
      end

      def baggage
        nil
      end
    end
  end
end
