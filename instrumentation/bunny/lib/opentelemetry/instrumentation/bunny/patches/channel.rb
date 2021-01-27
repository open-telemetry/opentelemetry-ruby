# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      module Patches
        # The Channel module contains the instrumentation patch the Channel#basic_get, Channel#basic_publish and Channel#handle_frameset methods
        module Channel
          def basic_get(queue, opts = { manual_ack: false })
            delivery_info, properties, payload = super

            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_receive_span(self, tracer, delivery_info, properties) do
              properties[:headers] ||= {}
              OpenTelemetry.propagation.text.inject(properties[:headers])
            end

            [delivery_info, properties, payload]
          end

          def basic_publish(payload, exchange, routing_key, opts = {})
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_send_span(self, tracer, exchange, routing_key) do
              opts[:headers] ||= {}
              OpenTelemetry.propagation.text.inject(opts[:headers])
              super(payload, exchange, routing_key, opts)
            end
          end

          # This method is called when rabbitmq pushes messages to subscribed consumers
          def handle_frameset(basic_deliver, properties, content)
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_receive_span(self, tracer, basic_deliver, properties) do
              properties[:headers] ||= {}
              OpenTelemetry.propagation.text.inject(properties[:headers])
            end

            super
          end

          private

          def tracer
            Bunny::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
