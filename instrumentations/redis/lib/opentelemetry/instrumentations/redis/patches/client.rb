# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentations
    module Redis
      module Patches
        # Module to prepend to Redis::Client for instrumentation
        module Client
          def call(*args, &block)
            response = nil

            tracer.in_span(
              Utils.format_command(args),
              attributes: client_attributes.merge(
                'db.statement' => Utils.format_statement(args)
              ),
              kind: :client
            ) do
              response = super(*args, &block)
            end

            response
          end

          def call_pipeline(*args, &block)
            response = nil

            tracer.in_span(
              'pipeline',
              attributes: client_attributes.merge(
                'db.statement' => Utils.format_pipeline_statement(args)
              ),
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

            {
              'db.type' => 'redis',
              'db.instance' => options[:db].to_s,
              'db.url' => "redis://#{host}:#{port}",
              'net.peer.name' => host,
              'net.peer.port' => port
            }
          end

          def tracer
            Redis::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
