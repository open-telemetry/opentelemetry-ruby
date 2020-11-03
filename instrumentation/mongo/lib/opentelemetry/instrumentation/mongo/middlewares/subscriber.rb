# frozen_string_literal: true

# Copyright 2019 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'command_serializer'

module OpenTelemetry
  module Instrumentation
    module Mongo
      module Middlewares
        # Event handler class for Mongo Ruby driver
        class Subscriber
          THREAD_KEY = :__opentelemetry_mongo_spans__

          def started(event) # rubocop:disable Metrics/AbcSize
            # start a trace and store it in the current thread; using the `operation_id`
            # is safe since it's a unique id used to link events together. Also only one
            # thread is involved in this execution so thread-local storage should be safe. Reference:
            # https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/monitoring.rb#L70
            # https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/monitoring/publishable.rb#L38-L56
            # TODO: decide naming convention
            collection = get_collection(event.command)
            span = tracer.start_span("#{collection || ''}.#{event.command_name}", kind: :client)
            set_span(event, span)

            serialized_command = CommandSerializer.new(event.command).serialize
            span.set_attribute('db.system', 'mongodb')
            span.set_attribute('db.name', event.database_name)
            span.set_attribute('db.operation', event.command_name)
            span.set_attribute('db.mongodb.collection', collection) if collection
            span.set_attribute('db.statement', serialized_command)
            span.set_attribute('net.peer.name', event.address.host)
            span.set_attribute('net.peer.port', event.address.port)
          end

          def failed(event)
            finish_event('failed', event) do |span|
              if event.is_a?(::Mongo::Monitoring::Event::CommandFailed)
                span.add_event('exception',
                          attributes: {
                            'exception.type' => 'CommandFailed',
                            'exception.message' => event.message
                          })
              end
            end
          end

          def succeeded(event)
            finish_event('succeeded', event)
          end

          private

          def finish_event(name, event)
            span = get_span(event)
            return unless span

            yield span if block_given?
          rescue StandardError => e
            OpenTelemetry.logger.debug("error when handling MongoDB '#{name}' event: #{e}")
          ensure
            # finish span to prevent leak and remove it from thread storage
            span&.finish
            clear_span(event)
          end

          def get_collection(command)
            collection = command.values.first
            collection if collection.is_a?(String)
          end

          def get_span(event)
            Thread.current[THREAD_KEY]&.[](event.request_id)
          end

          def set_span(event, span)
            Thread.current[THREAD_KEY] ||= {}
            Thread.current[THREAD_KEY][event.request_id] = span
          end

          def clear_span(event)
            Thread.current[THREAD_KEY]&.delete(event.request_id)
          end

          def tracer
            Mongo::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
