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
        ALWAYS_VALID_PAYLOAD_TYPES = [TrueClass, FalseClass, String, Numeric, Symbol].freeze

        def initialize(name:, tracer:)
          @span_name = name.split('.')[0..1].reverse.join(' ').freeze
          @tracer = tracer
        end

        def start(_name, _id, payload)
          span = @tracer.start_span(@span_name, kind: :internal)
          token = OpenTelemetry::Context.attach(
            OpenTelemetry::Trace.context_with_span(span)
          )

          [span, token]
        end

        def finish(_name, _id, payload)
          span = payload.delete(:__opentelemetry_span)
          token = payload.delete(:__opentelemetry_ctx_token)
          return unless span && token

          attrs = payload.map do |k, v|
            [k.to_s, sanitized_value(v)] if valid_payload_key?(k) && valid_payload_value?(v)
          end
          span.add_attributes(attrs.compact.to_h)

          if (e = payload[:exception_object])
            span.record_exception(e)
            span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
          end

          span.finish
          OpenTelemetry::Context.detach(token)
        end

        private

        def instrumentation_config
          Rails::Instrumentation.instance.config
        end

        def valid_payload_key?(key)
          %i[exception exception_object].none?(key) && instrumentation_config[:disallowed_notification_payload_keys].none?(key)
        end

        def valid_payload_value?(value)
          if value.is_a?(Array)
            return true if value.empty?

            value.map(&:class).uniq.size == 1 && ALWAYS_VALID_PAYLOAD_TYPES.any? { |t| value.first.is_a?(t) }
          else
            ALWAYS_VALID_PAYLOAD_TYPES.any? { |t| value.is_a?(t) }
          end
        end

        # We'll accept symbols as values, but stringify them; and we'll stringify symbols within an array.
        def sanitized_value(value)
          if value.is_a?(Array)
            value.map { |v| v.is_a?(Symbol) ? v.to_s : v }
          elsif value.is_a?(Symbol)
            value.to_s
          else
            value
          end
        end
      end
    end
  end
end
