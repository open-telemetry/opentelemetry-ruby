# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module ConsumerGroup
          # The JoinGroup module contains the instrumentation for consumer group join group event
          module JoinGroup
            extend self

            EVENT_NAME = 'join_group.consumer.kafka'
            SPAN_NAME = 'kafka.consumer.join_group'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |_name, start, finish, _id, _payload|
                attributes = { 'messaging.system' => 'kafka' }

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
