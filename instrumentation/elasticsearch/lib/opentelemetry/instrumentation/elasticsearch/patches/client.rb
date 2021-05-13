# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      module Patches
        # Module to prepend to Elasticsearch::Client for instrumentation
        module Client
          def perform_request(*args)
            response = nil

            tracer.in_span(
              'elasticsearch.query',
              attributes: tracing_attributes(*args),
              kind: :client
            ) do |span|
              response = super(*args)
              span.set_attribute('http.status_code', response.status)
            end
            response
          end

          private

          def tracing_attributes(*args)
            method = args[0]
            path = args[1]
            params = args[2]
            body = args[3]
            url = URI.parse(path).path

            params = JSON.generate(params) if params && !params.is_a?(String)
            body = JSON.generate(body) if body && !body.is_a?(String)

            {
              'elasticsearch.url' => url,
              'elasticsearch.method' => method,
              'elasticsearch.params' => params,
              'elasticsearch.body' => body || ''
            }.merge(connection_attributes)
          end

          def connection_attributes
            connection = transport.connections.first

            host = connection.host[:host] if connection
            port = connection.host[:port] if connection

            {
              'out.host' => host,
              'out.port' => port
            }
          end

          def tracer
            Elasticsearch::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
