# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Resque
      module Patches
        # Module to prepend to Resque for instrumentation
        module ResqueModule
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          # Module to prepend to Resque singleton class
          module ClassMethods
            def push(queue, item)
              attributes = {
                'messaging.system' => 'resque',
                'messaging.destination' => queue.to_s,
                'messaging.destination_kind' => 'queue'
              }

              if (job_class = item[:class])
                attributes['messaging.resque.job_class'] = job_class
              end

              span_name = case config[:span_naming]
                          when :queue then "#{queue} send"
                          when :job_class then "#{job_class} send"
                          else "#{queue} send"
                          end

              tracer.in_span(span_name, attributes: attributes, kind: :producer) do
                OpenTelemetry.propagation.inject(item)
                super
              end
            end

            def tracer
              Resque::Instrumentation.instance.tracer
            end

            def config
              Resque::Instrumentation.instance.config
            end
          end
        end
      end
    end
  end
end
