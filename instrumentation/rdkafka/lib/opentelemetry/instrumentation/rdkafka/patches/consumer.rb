# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rdkafka
      module Patches
        # The Consumer module contains the instrumentation patch for the Consumer class
        module Consumer
          def each
            super do |message|
              attributes = {
                'messaging.system' => 'kafka',
                'messaging.destination' => message.topic,
                'messaging.destination_kind' => 'topic',
                'messaging.kafka.partition' => message.partition,
                'messaging.kafka.offset' => message.offset
              }

              attributes['messaging.kafka.message_key'] = message.key if message.key
              parent_context = OpenTelemetry.propagation.extract(message.headers, getter: OpenTelemetry::Common::Propagation.symbol_key_getter)
              span_context = OpenTelemetry::Trace.current_span(parent_context).context
              links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid?

              OpenTelemetry::Context.with_current(parent_context) do
                tracer.in_span("#{message.topic} process", links: links, attributes: attributes, kind: :consumer) do
                  yield message
                end
              end
            end
          end

          def each_batch(max_items: 100, bytes_threshold: Float::INFINITY, timeout_ms: 250, yield_on_error: false, &block)
            super do |messages, error|
              if messages.empty?
                yield messages, error
              else
                attributes = {
                  'messaging.system' => 'kafka',
                  'messaging.destination_kind' => 'topic',
                  'messaging.kafka.message_count' => messages.size
                }

                links = messages.map do |message|
                  span_context = OpenTelemetry::Trace.current_span(OpenTelemetry.propagation.extract(message.headers, getter: OpenTelemetry::Common::Propagation.symbol_key_getter)).context
                  OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
                end
                links.compact!

                tracer.in_span('batch process', attributes: attributes, links: links, kind: :consumer) do
                  yield messages, error
                end
              end
            end
          end

          private

          def tracer
            Rdkafka::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
