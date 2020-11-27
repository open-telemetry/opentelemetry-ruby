# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The Client module contains the instrumentation patch the Producer#deliver_message method
        module Client
          def deliver_message(value, key: nil, headers: {}, topic:, partition: nil, partition_key: nil, retries: 1)
            attributes = {
              'messaging.system' => 'kafka',
              'messaging.destination' => topic
            }

            attributes['messaging.kafka.message_key'] = key if key
            attributes['messaging.kafka.partition'] = partition if partition

            tracer.in_span('send', attributes: attributes, kind: :producer) do
              OpenTelemetry.propagation.text.inject(headers)
              super
            end
          end

          def each_message(topic:, start_from_beginning: true, max_wait_time: 5, min_bytes: 1, max_bytes: 1_048_576, &block)
            super do |message|
              attributes = { 'messaging.system' => 'kafka' }
              attributes['messaging.destination'] = message.topic
              attributes['messaging.kafka.message_key'] = message.key if message.key
              attributes['messaging.kafka.partition'] = message.partition

              parent_context = OpenTelemetry.propagation.text.extract(message.headers)
              tracer.in_span('process', with_parent: parent_context, attributes: attributes, kind: :consumer) do
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
