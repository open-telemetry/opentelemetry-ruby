# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      class SpanSubscriber
        def start(name, id, payload)
          prev_ctx = OpenTelemetry::Context.current

          span_name = name.split('.')[0..1].reverse.join(' ')
          span = otel_tracer.start_span(span_name, kind: :internal)
          OpenTelemetry::Context.current = OpenTelemetry::Trace.context_with_span(span)

          [span, prev_ctx]
        end

        def finish(name, id, payload)
          span = payload.delete(:__opentelemetry_span)
          prev_ctx = payload.delete(:__opentelemetry_prev_ctx)
          if span && prev_ctx
            attrs = payload.reject do |k, v|
              [:exception, :exception_object].include?(k) || v.nil?
            end
            span.add_attributes(attrs.transform_keys(&:to_s))

            if e = payload[:exception_object]
              span.record_exception(e)
              span.status = OpenTelemetry::Trace::Status.new(
                OpenTelemetry::Trace::Status::ERROR,
                description: "Unhandled exception of type: #{e.class}"
              )
            end

            span.finish
            OpenTelemetry::Context.current = prev_ctx
          end
        end

        private

        def otel_tracer
          Rails::Instrumentation.instance.tracer
        end
      end
    end
  end
end
