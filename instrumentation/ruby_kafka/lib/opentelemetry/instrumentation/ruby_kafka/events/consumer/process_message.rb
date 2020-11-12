# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module Consumer
          # The ProcessMessage module contains the instrumentation for consumer process message event
          module ProcessMessage
            extend self

            EVENT_NAME = 'process_message.consumer.kafka'
            SPAN_NAME = 'kafka.consumer.process_message'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |_name, start, finish, _id, payload|
                attributes = { 'messaging.system' => 'kafka' }
                attributes['topic'] = payload[:topic] if payload.key?(:topic)
                attributes['message_key'] = payload[:key] if payload.key?(:key)
                attributes['partition'] = payload[:partition] if payload.key?(:partition)
                attributes['offset'] = payload[:offset] if payload.key?(:offset)
                attributes['offset_lag'] = payload[:offset_lag] if payload.key?(:offset_lag)

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
