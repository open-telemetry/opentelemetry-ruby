# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module OpenTracingShim
    # TracerShim provides a means of referencing
    # an OpenTelemetry::Tracer as a OpenTracing::Tracer
    class TracerShim
      HTTP_TEXT_FORMAT = OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat.new
      BINARY_FORMAT = OpenTelemetry::DistributedContext::Propagation::BinaryFormat.new
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
        @tracer.start_span(name,
                           with_parent: child_of,
                           attributes: tags,
                           links: references,
                           start_timestamp: start_time)
      end

      def start_span(operation_name,
                     child_of: nil,
                     references: nil,
                     start_time: Time.now,
                     tags: nil,
                     ignore_active_scope: false)
        @tracer.start_span(name,
                           with_parent: child_of,
                           attributes: tags,
                           links: references,
                           start_timestamp: start_time)
      end

      def inject(span_context, format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
          context = span_context.context
          HTTP_TEXT_FORMAT.inject(context, carrier)
        when OpenTracing::FORMAT_BINARY
          yield carrier, BINARY_FORMAT.to_bytes(span_context)
        else
          warn 'Unknown inject format'
        end
      end

      def extract(format, carrier)
        case format
        when OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_RACK
          HTTP_TEXT_FORMAT.extract(carrier)
        when OpenTracing::FORMAT_BINARY
          BINARY_FORMAT.from_bytes(carrier)
        else
          warn 'Unknown extract format'
        end
      end
    end
  end
end
