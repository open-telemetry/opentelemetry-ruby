# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Client
          # TracerMiddleware propagates context and instruments Sidekiq client
          # by way of its middleware system
          class TracerMiddleware
            def call(_worker_class, job, _queue, _redis_pool) # rubocop:disable Metrics/AbcSize
              attributes = {
                'messaging.system' => 'sidekiq',
                'messaging.sidekiq.job_class' => job['wrapped']&.to_s || job['class'],
                'messaging.message_id' => job['jid'],
                'messaging.destination' => job['queue'],
                'messaging.destination_kind' => 'queue'
              }
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              span_name = case config[:span_naming]
                          when :job_class then "#{job['wrapped']&.to_s || job['class']} send"
                          else "#{job['queue']} send"
                          end

              tracer.in_span(span_name, attributes: attributes, kind: :producer) do |span|
                OpenTelemetry.propagation.inject(job)
                span.add_event('created_at', timestamp: job['created_at'])
                yield
              end
            end

            private

            def config
              Sidekiq::Instrumentation.instance.config
            end

            def tracer
              Sidekiq::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
