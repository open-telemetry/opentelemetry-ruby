# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      # The PatchHelper module provides functionality shared between patches.
      #
      # For additional details around trace messaging semantics
      # See https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/messaging.md#messaging-attributes
      module PatchHelpers
        def self.with_send_span(tracer, exchange, routing_key, &block)
          attributes = basic_attributes(exchange, routing_key)
          destination = destination_name(exchange, routing_key)

          tracer.in_span("#{destination} send", attributes: attributes, kind: :producer, &block)
        end

        def self.with_process_span(tracer, delivery_info, properties, &block)
          with_consumer_span(tracer, 'process', delivery_info, properties, &block)
        end

        def self.with_receive_span(tracer, delivery_info, properties, &block)
          with_consumer_span(tracer, 'receive', delivery_info, properties, &block)
        end

        def self.with_consumer_span(tracer, operation, delivery_info, properties, &block)
          exchange = delivery_info[:exchange]
          routing_key = delivery_info[:routing_key]
          attributes = basic_attributes(exchange, routing_key)
          destination = destination_name(exchange, routing_key)

          parent_context = OpenTelemetry.propagation.text.extract(properties[:headers])
          span_context = OpenTelemetry::Trace.current_span(parent_context).context
          links = [OpenTelemetry::Trace::Link.new(span_context)] if span_context.valid?

          OpenTelemetry::Context.with_current(parent_context) do
            tracer.in_span("#{destination} #{operation}", links: links, attributes: attributes, kind: :consumer, &block)
          end
        end

        def self.destination_name(exchange, routing_key)
          [exchange, routing_key].compact.join('.')
        end

        def self.basic_attributes(exchange, routing_key)
          attributes = {
            'messaging.system' => 'rabbitmq',
            'messaging.destination' => exchange,
            'messaging.destination_kind' => 'topic',
            'messaging.protocol' => 'AMQP',
            'messaging.protocol_version' => '0.9.1'
          }
          attributes['messaging.rabbitmq.routing_key'] = routing_key if routing_key
          attributes
        end
      end
    end
  end
end
