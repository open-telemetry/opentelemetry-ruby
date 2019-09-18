# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    class TracerShim < OpenTracing::Tracer
      attr_reader :scope_manager

      def initialize(tracer)
        @tracer = tracer
        @scope_manager = ScopeManagerShim.new tracer
      end

      def active_span
        @tracer.current_span
      end

      def start_active_span(operation_name,
                            child_of: nil,
                            references: nil,
                            start_time: Time.now,
                            tags: nil,
                            ignore_active_scope: false,
                            finish_on_close: true)
        # TODO: this is busted as hell
        @tracer.in_span(name,
                        start_timestamp:start_time)
      end

      def start_span(operation_name,
                     child_of: nil,
                     references: nil,
                     start_time: Time.now,
                     tags: nil,
                     ignore_active_scope: false)
        # TODO: this is busted as hell
        @tracer.start_span(name,
                           with_parent: child_of,
                           start_timestamp: start_time)
      end

      def inject(span_context, format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK
          # Get the actual context
          # Use propogation to inject into the context
        else
          warn 'Unknown inject format'
        end
      end

      def extract(format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK
          # Use propogation to extract from context
        else
          warn 'Unknown extract format'
        end
      end
    end
  end
end
