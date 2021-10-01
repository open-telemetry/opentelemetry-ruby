# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rdkafka
      module Patches
        # The Consumer module contains the instrumentation patch for the Consumer class
        class CustomGetter
          def get(carrier, key)
            carrier[key.to_sym]
          end

          def keys(carrier)
            carrier.keys
          end
        end
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
              parent_context = OpenTelemetry.propagation.extract(message.headers, getter: CustomGetter.new)
              span_context = OpenTelemetry::Trace.current_span(parent_context).context
              links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid?

              OpenTelemetry::Context.with_current(parent_context) do
                tracer.in_span("#{message.topic} process", links: links, attributes: attributes, kind: :consumer) do
                  yield message
                end
              end
            end
          end

          def each_batch(min_bytes: 1, max_bytes: 10_485_760, max_wait_time: 1, automatically_mark_as_processed: true) # rubocop:disable Metrics/AbcSize
            super do |batch|
              attributes = {
                'messaging.system' => 'kafka',
                'messaging.destination' => batch.topic,
                'messaging.destination_kind' => 'topic',
                'messaging.kafka.partition' => batch.partition,
                'messaging.kafka.offset_lag' => batch.offset_lag,
                'messaging.kafka.highwater_mark_offset' => batch.highwater_mark_offset,
                'messaging.kafka.message_count' => batch.messages.count
              }

              links = batch.messages.map do |message|
                span_context = OpenTelemetry::Trace.current_span(OpenTelemetry.propagation.extract(message.headers)).context
                OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
              end
              links.compact!

              tracer.in_span("#{batch.topic} process", attributes: attributes, links: links, kind: :consumer) do
                yield batch
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
