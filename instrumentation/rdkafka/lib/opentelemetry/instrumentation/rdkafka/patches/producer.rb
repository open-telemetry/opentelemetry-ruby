# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rdkafka
      module Patches
        # The Producer module contains the instrumentation patch the Producer#produce method
        module Producer
          def produce(topic:, payload: nil, key: nil, partition: nil, partition_key: nil, timestamp: nil, headers: nil)
            attributes = {
              'messaging.system' => 'kafka',
              'messaging.destination' => topic,
              'messaging.destination_kind' => 'topic'
            }

            headers ||= {}

            tracer.in_span("#{topic} send", attributes: attributes, kind: :producer) do
              OpenTelemetry.propagation.inject(headers)
              super
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
