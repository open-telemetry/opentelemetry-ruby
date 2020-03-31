# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
    module Sidekiq
      module Middlewares
        module Client
          class TracerMiddleware
            def call(_worker_class, job, _queue, _redis_pool)
              tracer.in_span(
                job['wrapped']&.to_s || job['class'],
                attributes: {
                  'job_id' => job['jid'],
                  'messaging.destination' => job['queue'],
                  'created_at' => job['created_at'],
                },
                kind: :producer
              ) do |span|
                OpenTelemetry.propagation.text.inject(job)
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
