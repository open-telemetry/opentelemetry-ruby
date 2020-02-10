# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # A SpanContext provides a means of treating an OpenTelemetry::Trace::SpanContext
      # as an OpenTracing::SpanContext
      class SpanContext
        attr_reader :context

        # Returns a new {SpanContext}
        #
        # @param [SpanContext] context the OpenTelemetry SpanContext to shim
        # @param [DistributedContext] where the baggage is stored
        # @return [SpanContext]
        def initialize(context, dist_context: nil)
          @context = context
          dist_context ||= OpenTelemetry::Context.current
          @dist_context = dist_context
        end

        def trace_id
          context.trace_id
        end

        def span_id
          context.span_id
        end

        def baggage
          @dist_context
        end
      end
    end
  end
end
