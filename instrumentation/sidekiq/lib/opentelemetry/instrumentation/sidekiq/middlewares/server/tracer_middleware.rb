# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      module Middlewares
        module Server
          # TracerMiddleware propagates context and instruments Sidekiq requests
          # by way of its middleware system
          class TracerMiddleware
            def call(_worker, msg, _queue) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
              attributes = {
                'messaging.system' => 'sidekiq',
                'messaging.sidekiq.job_class' => msg['wrapped']&.to_s || msg['class'],
                'messaging.message_id' => msg['jid'],
                'messaging.destination' => msg['queue'],
                'messaging.destination_kind' => 'queue',
                'messaging.operation' => 'process'
              }
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              span_name = case config[:span_naming]
                          when :job_class then "#{msg['wrapped']&.to_s || msg['class']} process"
                          else "#{msg['queue']} process"
                          end

              extracted_context = OpenTelemetry.propagation.extract(msg)
              OpenTelemetry::Context.with_current(extracted_context) do
                if config[:propagation_style] == :child
                  tracer.in_span(span_name, attributes: attributes, kind: :consumer) do |span|
                    span.add_event('created_at', timestamp: msg['created_at'])
                    span.add_event('enqueued_at', timestamp: msg['enqueued_at'])
                    yield
                  end
                else
                  links = []
                  span_context = OpenTelemetry::Trace.current_span(extracted_context).context
                  links << OpenTelemetry::Trace::Link.new(span_context) if config[:propagation_style] == :link && span_context.valid?
                  span = tracer.start_root_span(span_name, attributes: attributes, links: links, kind: :consumer)
                  OpenTelemetry::Trace.with_span(span) do
                    span.add_event('created_at', timestamp: msg['created_at'])
                    span.add_event('enqueued_at', timestamp: msg['enqueued_at'])
                    yield
                  rescue Exception => e # rubocop:disable Lint/RescueException
                    span.record_exception(e)
                    span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
                    raise e
                  ensure
                    span.finish
                  end
                end
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
