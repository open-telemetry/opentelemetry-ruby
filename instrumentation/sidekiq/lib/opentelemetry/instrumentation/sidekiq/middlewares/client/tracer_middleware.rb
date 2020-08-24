# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Client
          class TracerMiddleware
            def call(_worker_class, job, _queue, _redis_pool)
              tracer.in_span(
                job['wrapped']&.to_s || job['class'],
                attributes: {
                  'messaging.message_id' => job['jid'],
                  'messaging.destination' => job['queue'],
                },
                kind: :producer
              ) do |span|
                OpenTelemetry.propagation.text.inject(job)
                span.add_event('created_at', timestamp: job['created_at'])
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
