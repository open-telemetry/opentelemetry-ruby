# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Resque
      module Patches
        # Module to prepend to Resque::Job for instrumentation
        module ResqueJob
          def perform # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            job_class = payload_class_name

            attributes = {
              'messaging.system' => 'resque',
              'messaging.destination' => queue.to_s,
              'messaging.destination_kind' => 'queue',
              'messaging.resque.job_class' => job_class
            }

            span_name = if config[:job_class_span_names]
                          "#{job_class} process"
                        else
                          "#{queue} process"
                        end

            extracted_context = OpenTelemetry.propagation.extract(@payload)

            links = []
            if config[:propagation_style] == :link
              span_context = OpenTelemetry::Trace.current_span(extracted_context).context
              links << OpenTelemetry::Trace::Link.new(span_context) if span_context.valid?
            end

            parent_context = (config[:propagation_style] == :child ? extracted_context : OpenTelemetry::Context.current)

            OpenTelemetry::Context.with_current(parent_context) do
              tracer.in_span(span_name, attributes: attributes, links: links, kind: :consumer) do
                super
              end
            end
          end

          private

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
