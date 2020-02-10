# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Bridge
    module OpenTracing
      # Tracer provides a means of referencing
      # an OpenTelemetry::Tracer as an OpenTracing::Tracer
      class Tracer
        attr_reader :tracer

        def initialize(tracer)
          @tracer = tracer
        end

        def active_span
          scope = ScopeManager.instance.active
          scope&.span
        end

        def start_active_span(operation_name,
                              child_of: nil,
                              references: nil,
                              start_time: Time.now,
                              tags: nil,
                              ignore_active_scope: false,
                              finish_on_close: true,
                              &block)
          child_of = child_of.span unless child_of.instance_of? OpenTelemetry::Trace::Span
          span = @tracer.start_span(operation_name,
                                    with_parent: child_of,
                                    attributes: tags,
                                    links: references,
                                    start_timestamp: start_time)
          wrapped = Span.new(span, dist_context: span.context)
          scope = Scope.new(ScopeManager.instance, wrapped, finish_on_close)
          if block_given?
            yield scope
            return @tracer.with_span(span, &block)
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
          child_of = child_of.span unless child_of.instance_of? OpenTelemetry::Trace::Span
          span = @tracer.start_span(operation_name,
                                    with_parent: child_of,
                                    attributes: tags,
                                    links: references,
                                    start_timestamp: start_time)
          wrapped = Span.new(span, dist_context: span.context)
          if block_given?
            yield wrapped
            return @tracer.with_span(span, &block)
          end
          wrapped
        end

        def inject(span_context, format, carrier)
          context = OpenTelemetry::Context.current
          span = OpenTelemetry::Trace::Span.new(span_context: span_context.context)
          context = context.set_value(OpenTelemetry::Trace::Propagation::ContextKeys.current_span_key, span)
          case format
          when ::OpenTracing::FORMAT_TEXT_MAP
            OpenTelemetry::Trace::Propagation.http_trace_context_injector.inject(context, carrier) do |c, k, v|
              return c, k, v
            end
          when ::OpenTracing::FORMAT_RACK
            OpenTelemetry::Trace::Propagation.http_trace_context_injector.inject(context, carrier) do |c, k, v|
              return c, k, v
            end
          when ::OpenTracing::FORMAT_BINARY
            OpenTelemetry::Trace::Propagation.binary_format.to_bytes(context)
          else
            warn 'Unknown inject format'
          end
        end

        def extract(format, carrier)
          context = OpenTelemetry::Context.current
          case format
          when ::OpenTracing::FORMAT_TEXT_MAP
            OpenTelemetry::Trace::Propagation.http_trace_context_extractor.extract(context, carrier)
          when ::OpenTracing::FORMAT_RACK
            OpenTelemetry::Trace::Propagation.http_trace_context_extractor.extract(context, carrier)
          when ::OpenTracing::FORMAT_BINARY
            OpenTelemetry::Trace::Propagation.binary_format.from_bytes(carrier)
          else
            warn 'Unknown extract format'
          end
        end
      end
    end
  end
end
