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
          def perform_request(method, path, params = {}, body = nil, headers = nil)
            attributes = {
              'http.target' => path,
              'http.method' => method,
              'elasticsearch.params' => params,
              'elasticsearch.body' => body || ''
            }

            attributes['elasticsearch.params'] = JSON.generate(params) if params && !params.is_a?(String)
            attributes['elasticsearch.body'] = JSON.generate(body) if body && !body.is_a?(String)

            if (connection = transport.connections.first)
              attributes['http.host'] = connection.host[:host]
              attributes['net.peer.port'] = connection.host[:port]
            end

            tracer.in_span('elasticsearch.query', attributes: attributes, kind: :client) do |span|
              super.tap do |response|
                span.set_attribute('http.status_code', response.status)
              end
            end
          end

          private

          def tracer
            Elasticsearch::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
