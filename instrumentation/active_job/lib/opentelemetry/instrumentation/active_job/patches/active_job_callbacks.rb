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
          def self.prepended(base) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            base.class_eval do # rubocop:disable Metrics/BlockLength
              around_enqueue do |job, block|
                span_kind = job.class.queue_adapter_name == 'inline' ? :client : :producer
                span_name = "#{otel_config[:span_naming] == :job_class ? job.class : job.queue_name} send"
                span_attributes = job_attributes(job)
                otel_tracer.in_span(span_name, attributes: span_attributes, kind: span_kind) do
                  OpenTelemetry.propagation.inject(job.metadata)
                  block.call
                end
              end

              around_perform do |job, block| # rubocop:disable Metrics/BlockLength
                span_kind = job.class.queue_adapter_name == 'inline' ? :server : :consumer
                span_name = "#{otel_config[:span_naming] == :job_class ? job.class : job.queue_name} process"
                span_attributes = job_attributes(job).merge('messaging.operation' => 'process')

                extracted_context = OpenTelemetry.propagation.extract(job.metadata)
                OpenTelemetry::Context.with_current(extracted_context) do
                  if otel_config[:propagation_style] == :child
                    otel_tracer.in_span(span_name, attributes: span_attributes, kind: span_kind) do |span|
                      span.set_attribute('messaging.active_job.executions', job.executions)
                      block.call
                    end
                  else
                    span_links = []
                    if otel_config[:propagation_style] == :link
                      span_context = OpenTelemetry::Trace.current_span(extracted_context).context
                      span_links << OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
                    end

                    root_span = otel_tracer.start_root_span(span_name, attributes: span_attributes, links: span_links, kind: span_kind)
                    OpenTelemetry::Trace.with_span(root_span) do |span|
                      span.set_attribute('messaging.active_job.executions', job.executions)
                      block.call
                    rescue Exception => e # rubocop:disable Lint/RescueException
                      span.record_exception(e)
                      span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
                      raise e
                    ensure
                      root_span.finish
                    end
                  end
                end
              ensure
                # We may be in a job system (eg: resque) that forks and kills worker processes often.
                # We don't want to lose spans by not flushing any span processors, so we optionally force it here.
                OpenTelemetry.tracer_provider.force_flush if otel_config[:force_flush]
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

          def otel_config
            ActiveJob::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
