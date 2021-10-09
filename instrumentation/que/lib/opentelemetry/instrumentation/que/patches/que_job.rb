# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Que
      module Patches
        # Module to prepend to Que::Job for instrumentation
        module QueJob
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          # Module to prepend to Que singleton class
          module ClassMethods
            def enqueue(*args, tags: nil, **arg_opts)
              tracer = Que::Instrumentation.instance.tracer
              otel_config = Que::Instrumentation.instance.config

              tracer.in_span('send', kind: :producer) do |span|
                # Que doesn't have a good place to store metadata. There are
                # basically two options: the job payload and the job tags.
                #
                # Using the job payload is very brittle. We'd have to modify
                # existing Hash arguments or add a new argument when there are
                # no arguments we can modify. If the server side is not using
                # this instrumentation yet (e.g. old jobs before the
                # instrumentation was added or when instrumentation is being
                # added to client side first) then the server can error out due
                # to unexpected payload.
                #
                # The second option (which we are using here) is to use tags.
                # They also are not meant for tracing information but they are
                # much safer to use than modifying the payload.
                if otel_config[:propagation_style] != :none
                  tags ||= []
                  OpenTelemetry.propagation.inject(tags, setter: TagSetter)
                end

                job = super(*args, tags: tags, **arg_opts)

                span.name = "#{job.que_attrs[:job_class]} send"
                span.add_attributes(QueJob.job_attributes(job))

                job
              end
            end
          end

          def self.job_attributes(job)
            attributes = {
              'messaging.system' => 'que',
              'messaging.destination_kind' => 'queue',
              'messaging.operation' => 'send',
              'messaging.destination' => job.que_attrs[:queue] || 'default',
              'messaging.que.job_class' => job.que_attrs[:job_class],
              'messaging.que.priority' => job.que_attrs[:priority] || 100
            }
            attributes['messaging.message_id'] = job.que_attrs[:id] if job.que_attrs[:id]
            attributes
          end
        end
      end
    end
  end
end
