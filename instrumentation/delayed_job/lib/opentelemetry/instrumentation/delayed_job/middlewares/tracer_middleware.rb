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

              tracer.in_span('delayed_job.enqueue', kind: :producer) do |span|
                yield job
                add_attributes(span, job)
                add_events(span, job)
              end
            end

            def instrument_invoke(job, &block) # rubocop:disable Metrics/AbcSize
              return block.call(job) unless enabled?

              tracer.in_span('delayed_job.invoke', kind: :consumer) do |span|
                add_attributes(span, job)
                span.set_attribute('delayed_job.attempts', job.attempts) if job.attempts
                span.set_attribute('delayed_job.locked_by', job.locked_by) if job.locked_by
                add_events(span, job)
                begin
                  yield job
                rescue StandardError => e
                  span.set_attribute('error', true)
                  span.set_attribute('error.kind', e.class.name)
                  span.set_attribute('message', e.message&.[](0...120))
                  raise e
                end
              end
            end

            # def flush(worker, &block)
            #   yield worker
            #
            #   tracer.shutdown if enabled?
            # end

            protected

            def add_attributes(span, job)
              span.set_attribute('component', 'delayed_job')
              span.set_attribute('delayed_job.id', job.id)
              span.set_attribute('delayed_job.name', job_name(job))
              span.set_attribute('delayed_job.queue', job.queue) if job.queue
              span.set_attribute('delayed_job.priority', job.priority)
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
              return job.payload_object.job_data['job_class'] if job.payload_object.respond_to?(:job_data)

              job.name
            end
          end

          callbacks do |lifecycle|
            lifecycle.around(:enqueue, &method(:instrument_enqueue))
            lifecycle.around(:invoke_job, &method(:instrument_invoke))
            # lifecycle.around(:execute, &method(:flush))
          end
        end
      end
    end
  end
end
