# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'delayed/plugin'

module OpenTelemetry
  module Instrumentation
    module DelayedJob
      module Middlewares
        # Delayed Job plugin that instruments invoke_job and other hooks
        class TracerMiddleware < Delayed::Plugin
          class << self
            def instrument_enqueue(job, &block)
              return block.call(job) unless enabled?

              attributes = build_attributes(job)
              attributes['messaging.operation'] = 'send'
              tracer.in_span("#{job_queue(job)} send", attributes: attributes, kind: :producer) do |span|
                yield job
                span.set_attribute('messaging.message_id', job.id)
                add_events(span, job)
              end
            end

            def instrument_invoke(job, &block)
              return block.call(job) unless enabled?

              attributes = build_attributes(job)
              attributes['messaging.delayed_job.attempts'] = job.attempts if job.attempts
              attributes['messaging.delayed_job.locked_by'] = job.locked_by if job.locked_by
              attributes['messaging.operation'] = 'process'
              attributes['messaging.message_id'] = job.id
              tracer.in_span("#{job_queue(job)} process", attributes: attributes, kind: :consumer) do |span|
                add_events(span, job)
                yield job
              end
            end

            protected

            def build_attributes(job)
              {
                'messaging.system' => 'delayed_job',
                'messaging.destination' => job_queue(job),
                'messaging.destination_kind' => 'queue',
                'messaging.delayed_job.name' => job_name(job),
                'messaging.delayed_job.priority' => job.priority
              }
            end

            def add_events(span, job)
              span.add_event('created_at', timestamp: job.created_at)
              span.add_event('run_at', timestamp: job.run_at) if job.run_at
              span.add_event('locked_at', timestamp: job.locked_at) if job.locked_at
            end

            def enabled?
              DelayedJob::Instrumentation.instance.enabled?
            end

            def tracer
              DelayedJob::Instrumentation.instance.tracer
            end

            def job_name(job)
              # If Delayed Job is used via ActiveJob then get the job name from the payload
              if job.payload_object.respond_to?(:job_data)
                job.payload_object.job_data['job_class']
              else
                job.name
              end
            end

            def job_queue(job)
              job.queue || 'default'
            end
          end

          callbacks do |lifecycle|
            lifecycle.around(:enqueue, &method(:instrument_enqueue))
            lifecycle.around(:invoke_job, &method(:instrument_invoke))
          end
        end
      end
    end
  end
end
