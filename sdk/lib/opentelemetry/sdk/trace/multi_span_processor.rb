# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # Implementation of the SpanProcessor duck type that simply forwards all
      # received events to a list of SpanProcessors.
      class MultiSpanProcessor
        # Creates a new {MultiSpanProcessor}.
        #
        # @param [Enumerable<SpanProcessor>] span_processors a collection of
        #   SpanProcessors.
        # @return [MultiSpanProcessor]
        def initialize(span_processors)
          @span_processors = span_processors.to_a.freeze
        end

        def on_start(span)
          @span_processors.each { |processor| processor.on_start(span) }
        end

        def on_end(span)
          @span_processors.each { |processor| processor.on_end(span) }
        end

        def shutdown
          @span_processors.each(&:shutdown)
        end
      end
    end
  end
end
