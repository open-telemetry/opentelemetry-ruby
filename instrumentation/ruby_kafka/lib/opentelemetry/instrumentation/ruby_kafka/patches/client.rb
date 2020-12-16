# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The Client module contains the instrumentation patch the Client#deliver_message and Client#each_message methods.
        module Client
          def deliver_message(value, key: nil, headers: {}, topic:, partition: nil, partition_key: nil, retries: 1)
            attributes = {
              'messaging.system' => 'kafka',
              'messaging.destination' => topic,
              'messaging.destination_kind' => 'topic'
            }

            attributes['messaging.kafka.message_key'] = key if key
            attributes['messaging.kafka.partition'] = partition if partition

            tracer.in_span("#{topic} send", attributes: attributes, kind: :producer) do
              OpenTelemetry.propagation.text.inject(headers)
              super
            end
          end

          def each_message(topic:, start_from_beginning: true, max_wait_time: 5, min_bytes: 1, max_bytes: 1_048_576, &block)
            super do |message|
              attributes = {
                'messaging.system' => 'kafka',
                'messaging.destination' => message.topic,
                'messaging.destination_kind' => 'topic',
                'messaging.kafka.partition' => message.partition
              }

              attributes['messaging.kafka.message_key'] = message.key if message.key

              parent_context = OpenTelemetry.propagation.text.extract(message.headers)
              tracer.in_span("#{topic} process", with_parent: parent_context, attributes: attributes, kind: :consumer) do
                yield message
              end
            end
          end

          private

          def tracer
            RubyKafka::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
