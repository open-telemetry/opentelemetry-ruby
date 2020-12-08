# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module Producer
          # The DeliverMessages module contains the instrumentation for producer deliver messages event
          module DeliverMessages
            extend self

            EVENT_NAME = 'deliver_messages.producer.kafka'
            SPAN_NAME = 'kafka.producer.deliver_messages'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe('deliver_messages.producer.kafka') do |_name, start, finish, _id, payload|
                attributes = { 'messaging.system' => 'kafka' }
                attributes['messaging.kafka.message_count'] = payload[:message_count] if payload.key?(:message_count)
                attributes['messaging.kafka.delivered_message_count'] = payload[:delivered_message_count] if payload.key?(:delivered_message_count)
                attributes['messaging.kafka.attempts'] = payload[:attempts] if payload.key?(:attempts)

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
