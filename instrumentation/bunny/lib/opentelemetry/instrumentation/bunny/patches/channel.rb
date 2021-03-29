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
            attributes = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.basic_attributes(self, '', nil)

            tracer.in_span("#{queue} receive", attributes: attributes, kind: :consumer) do |span, _ctx|
              delivery_info, properties, payload = super

              return [delivery_info, properties, payload] unless delivery_info

              exchange = delivery_info.exchange
              routing_key = delivery_info.routing_key
              destination = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.destination_name(exchange, routing_key)
              destination_kind = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.destination_kind(self, exchange)
              span.name = "#{destination} receive"
              span['messaging.destination'] = exchange
              span['messaging.destination_kind'] = destination_kind
              span['messaging.rabbitmq.routing_key'] = routing_key if routing_key
              span['messaging.operation'] = 'receive'

              inject_context_into_property(properties, :tracer_receive_headers)

              [delivery_info, properties, payload]
            end
          end

          def basic_publish(payload, exchange, routing_key, opts = {})
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_send_span(self, tracer, exchange, routing_key) do
              inject_context_into_property(opts, :headers)

              super(payload, exchange, routing_key, opts)
            end
          end

          # This method is called when rabbitmq pushes messages to subscribed consumers
          def handle_frameset(basic_deliver, properties, content)
            exchange = basic_deliver.exchange
            routing_key = basic_deliver.routing_key
            attributes =  OpenTelemetry::Instrumentation::Bunny::PatchHelpers.basic_attributes(self, exchange, routing_key)
            destination = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.destination_name(exchange, routing_key)

            tracer.in_span("#{destination} receive", attributes: attributes, kind: :consumer) do
              inject_context_into_property(properties, :tracer_receive_headers)
            end

            super
          end

          private

          def tracer
            Bunny::Instrumentation.instance.tracer
          end

          def inject_context_into_property(properties, key)
            properties[key] ||= {}
            OpenTelemetry.propagation.inject(properties[key])
          end
        end
      end
    end
  end
end
