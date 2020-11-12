# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module Consumer
          # The ProcessBatch module contains the instrumentation for consumer process batch event
          module ProcessBatch
            extend self

            EVENT_NAME = 'process_batch.consumer.kafka'
            SPAN_NAME = 'kafka.consumer.process_batch'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |_name, start, finish, _id, payload|
                attributes = { 'messaging.system' => 'kafka' }

                attributes['topic'] = payload[:topic] if payload.key?(:topic)
                attributes['message_count'] = payload[:message_count] if payload.key?(:message_count)
                attributes['partition'] = payload[:partition] if payload.key?(:partition)
                attributes['highwater_mark_offset'] = payload[:highwater_mark_offset] if payload.key?(:highwater_mark_offset)
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
