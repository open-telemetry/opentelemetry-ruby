# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The Producer module contains the instrumentation patch the Producer#produce method
        module Producer
          def produce(value, key: nil, headers: {}, topic:, partition: nil, partition_key: nil, create_time: Time.now)
            attributes = {
              'messaging.system' => 'kafka',
              'messaging.destination' => topic,
              'messaging.destination_kind' => 'topic'
            }

            tracer.in_span('send', attributes: attributes, kind: :producer) do
              OpenTelemetry.propagation.text.inject(headers)
              super
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
