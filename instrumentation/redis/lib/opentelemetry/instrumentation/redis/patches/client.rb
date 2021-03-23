# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        # Module to prepend to Redis::Client for instrumentation
        module Client
          def call(*args, &block)
            response = nil

            attributes = client_attributes
            attributes['db.statement'] = Utils.format_statement(args)
            tracer.in_span(
              Utils.format_command(args),
              attributes: attributes,
              kind: :client
            ) do
              response = super(*args, &block)
            end

            response
          end

          def call_pipeline(*args, &block)
            response = nil

            attributes = client_attributes
            attributes['db.statement'] = Utils.format_pipeline_statement(args)
            tracer.in_span(
              'pipeline',
              attributes: attributes,
              kind: :client
            ) do
              response = super(*args, &block)
            end

            response
          end

          private

          def client_attributes
            host = options[:host]
            port = options[:port]

            attributes = {
              'db.system' => 'redis',
              'net.peer.name' => host,
              'net.peer.port' => port
            }
            attributes['db.redis.database_index'] = options[:db] unless options[:db].zero?
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]
            attributes.merge(OpenTelemetry::Instrumentation::Redis.attributes)
          end

          def tracer
            Redis::Instrumentation.instance.tracer
          end

          def config
            Redis::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
