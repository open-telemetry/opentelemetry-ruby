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
