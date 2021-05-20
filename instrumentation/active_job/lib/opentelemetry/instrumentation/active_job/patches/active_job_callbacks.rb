# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Patches
        # Module to prepend to ActiveJob::Base for instrumentation.
        module ActiveJobCallbacks
          def self.prepended(base) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            base.class_eval do
              around_enqueue do |job, block|
                span_kind = job.class.queue_adapter_name == 'inline' ? :client : :producer
                span_name = "#{job.class} send"
                span_attributes = job_attributes(job)
                otel_tracer.in_span(span_name, attributes: span_attributes, kind: span_kind) do |span|
                  OpenTelemetry.propagation.inject(job.metadata)
                  block.call
                end
              end

              around_perform do |job, block|
                span_kind = job.class.queue_adapter_name == 'inline' ? :server : :consumer
                span_name = "#{job.class} process"
                span_attributes = job_attributes(job).merge('messaging.operation' => 'process')

                propagated_context = OpenTelemetry.propagation.extract(job.metadata)

                if config[:context_propagation] == :link
                  span_links = [
                    OpenTelemetry::Trace::Link.new(OpenTelemetry::Trace.current_span(propagated_context).context)
                  ]
                end

                parent_context = (config[:context_propagation] == :child ? propagated_context : OpenTelemetry::Context.current)
                OpenTelemetry::Context.with_current(parent_context) do
                  otel_tracer.in_span(span_name, attributes: span_attributes, links: span_links, kind: span_kind) do |span|
                    span.set_attribute('messaging.active_job.executions', job.executions)
                    block.call
                  end
                end
              ensure
                # We may be in a job system (eg: resque) that forks and kills worker processes often.
                # We don't want to lose spans by not flushing any span processors, so we force it here.
                otel_tracer.tracer_provider.force_flush
              end
            end
          end

          private

          def job_attributes(job)
            otel_attributes = {
              'messaging.destination_kind' => 'queue',
              'messaging.system' => job.class.queue_adapter_name,
              'messaging.destination' => job.queue_name,
              'messaging.message_id' => job.job_id,
              'messaging.active_job.scheduled_at' => job.scheduled_at,
              'messaging.active_job.priority' => job.priority
            }

            otel_attributes['net.transport'] = 'inproc' if %w[async inline].include?(job.class.queue_adapter_name)

            otel_attributes.compact
          end

          def otel_tracer
            ActiveJob::Instrumentation.instance.tracer
          end

          def config
            ActiveJob::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
