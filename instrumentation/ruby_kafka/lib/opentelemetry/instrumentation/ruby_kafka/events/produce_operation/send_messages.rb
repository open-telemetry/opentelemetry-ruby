# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module ProduceOperation
          # The SendMessages module contains the instrumentation for produce operation send messages event
          module SendMessages
            extend self

            EVENT_NAME = 'send_messages.producer.kafka'
            SPAN_NAME = 'kafka.producer.send_messages'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |_name, start, finish, _id, payload|
                attributes = { 'messaging.system' => 'kafka' }
                attributes['messaging.kafka.message_count'] = payload[:message_count] if payload.key?(:message_count)
                attributes['messaging.kafka.sent_message_count'] = payload[:sent_message_count] if payload.key?(:sent_message_count)

                span = tracer.start_span(SPAN_NAME, attributes: attributes, start_timestamp: start, kind: :client)
                span.finish(end_timestamp: finish)
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
end
