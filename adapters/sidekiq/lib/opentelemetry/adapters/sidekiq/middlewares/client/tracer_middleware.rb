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
            def call(worker_class, job, _queue, _redis_pool)
              tracer.in_span(
                worker_class,
                attributes: {
                  jid: job['jid'],
                  created_at: job['created_at'],
                },
                kind: :producer
              ) do |span|
                OpenTelemetry.propagation.inject(job, injectors: OpenTelemetry.propagation.job_injectors)
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
