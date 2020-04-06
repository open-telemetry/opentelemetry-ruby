# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Sidekiq
      module Middlewares
        module Server
          class TracerMiddleware
            def call(_worker, msg, _queue)
              parent_context = OpenTelemetry.propagation.text.extract(msg)
              tracer.in_span(
                msg['wrapped']&.to_s || msg['class'],
                attributes: {
                  'job_id' => msg['jid'],
                  'messaging.destination' => msg['queue'],
                  'created_at' => msg['created_at'],
                  'enqueued_at' => msg['enqueued_at'],
                },
                with_parent_context: parent_context,
                kind: :consumer
              ) do |span|
                yield
              end
            end

            private

            def tracer
              Sidekiq::Adapter.instance.tracer
            end
          end
        end
      end
    end
  end
end
