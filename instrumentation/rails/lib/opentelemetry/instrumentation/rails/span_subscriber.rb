# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rails
      # The SpanSubscriber is a special ActiveSupport::Notification subscription
      # handler which turns notifications into generic spans, taking care to handle
      # context appropriately.
      class SpanSubscriber
        def initialize(name:, tracer:)
          @span_name = name.split('.')[0..1].reverse.join(' ').freeze
          @tracer = tracer
        end

        def start(_name, _id, payload)
          prev_ctx = OpenTelemetry::Context.current

          span = @tracer.start_span(@span_name, kind: :internal)
          OpenTelemetry::Context.current = OpenTelemetry::Trace.context_with_span(span)

          [span, prev_ctx]
        end

        def finish(_name, _id, payload)
          span = payload.delete(:__opentelemetry_span)
          prev_ctx = payload.delete(:__opentelemetry_prev_ctx)
          return unless span && prev_ctx

          attrs = payload.reject do |k, v|
            %i[exception exception_object].include?(k) || v.nil?
          end
          span.add_attributes(attrs.transform_keys(&:to_s))

          if (e = payload[:exception_object])
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
    end
  end
end
