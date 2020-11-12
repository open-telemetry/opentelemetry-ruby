# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Events
        module Connection
          # The Request module contains the instrumentation for connection request event
          module Request
            extend self

            EVENT_NAME = 'request.connection.kafka'
            SPAN_NAME = 'kafka.connection.request'

            def subscribe!
              ::ActiveSupport::Notifications.subscribe(EVENT_NAME) do |_name, start, finish, _id, payload|
                attributes = { 'messaging.system' => 'kafka' }
                attributes['request_size'] = payload[:request_size] if payload.key?(:request_size)
                attributes['response_size'] = payload[:response_size] if payload.key?(:response_size)

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
