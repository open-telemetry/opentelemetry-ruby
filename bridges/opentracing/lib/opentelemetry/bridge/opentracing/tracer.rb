# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Tracer provides a means of referencing
      # an OpenTelemetry::Tracer as a OpenTracing::Tracer
      class Tracer
        HTTP_TEXT_FORMAT = OpenTelemetry::DistributedContext::Propagation::HTTPTextFormat.new
        BINARY_FORMAT = OpenTelemetry::DistributedContext::Propagation::BinaryFormat.new

        def active_span
          OpenTelemetry.tracer.current_span
        end

        def start_active_span(operation_name,
                              child_of: nil,
                              references: nil,
                              start_time: Time.now,
                              tags: nil,
                              ignore_active_scope: false,
                              finish_on_close: true,
                              &block)
          span = OpenTelemetry.tracer.start_span(operation_name,
                                                 with_parent: child_of,
                                                 attributes: tags,
                                                 links: references,
                                                 start_timestamp: start_time)
          scope = Scope.new(ScopeManager.new, span, finish_on_close)
          if block_given?
            yield scope
            return OpenTelemetry.tracer.with_span(span, &block)
          end

          scope
        end

        def start_span(operation_name,
                       child_of: nil,
                       references: nil,
                       start_time: Time.now,
                       tags: nil,
                       ignore_active_scope: false,
                       &block)
          span = OpenTelemetry.tracer.start_span(operation_name,
                                                 with_parent: child_of,
                                                 attributes: tags,
                                                 links: references,
                                                 start_timestamp: start_time)
          if block_given?
            yield span
            return OpenTelemetry.tracer.with_span(span, &block)
          end
          span
        end

        def inject(span_context, format, carrier)
          case format
          when ::OpenTracing::FORMAT_TEXT_MAP, ::OpenTracing::FORMAT_RACK
            context = span_context.context
            HTTP_TEXT_FORMAT.inject(context, carrier) { |c, k, v| return c, k, v }
          when ::OpenTracing::FORMAT_BINARY
            # TODO: I don't think this is right
            yield carrier, TraceParent::TRACE_PARENT_HEADER, BINARY_FORMAT.to_bytes(span_context)
          else
            warn 'Unknown inject format'
          end
        end

        def extract(format, carrier)
          case format
          when ::OpenTracing::FORMAT_TEXT_MAP, ::OpenTracing::FORMAT_RACK
            HTTP_TEXT_FORMAT.extract(carrier) {}
          when ::OpenTracing::FORMAT_BINARY
            BINARY_FORMAT.from_bytes(carrier)
          else
            warn 'Unknown extract format'
          end
        end
      end
    end
  end
end
