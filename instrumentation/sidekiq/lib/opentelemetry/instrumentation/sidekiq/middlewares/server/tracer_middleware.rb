# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Server
          # TracerMiddleware propagates context and instruments Sidekiq requests
          # by way of its middleware system
          class TracerMiddleware
            def call(_worker, msg, _queue)
              parent_context = OpenTelemetry.propagation.text.extract(msg)
              tracer.in_span(
                "#{msg['queue']} process",
                attributes: {
                  'messaging.system' => 'sidekiq',
                  'messaging.message_id' => msg['jid'],
                  'messaging.destination' => msg['queue'],
                  'messaging.destination_type' => 'queue',
                },
                with_parent: parent_context,
                kind: :consumer
              ) do |span|
                span.add_event('created_at', timestamp: msg['created_at'])
                span.add_event('enqueued_at', timestamp: msg['enqueued_at'])
                yield
              end
            end

            private

            def tracer
              Sidekiq::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
