# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # All Elasticsearch requests go through Client#perform_request.
      module Client
        def perform_request(method, path, params = {}, body = nil, headers = nil)
          # todo: make sure all different transport drivers (typhoeus, httpclient, etc., all use same interface for host)
          attributes = {
            'db.system' => 'elasticsearch',
            'net.protocol' => 'ip_tcp'
          }
          attributes['db.statement'] = params.to_json unless params == {}
          attributes['db.statement'] += body if body

          host_hash = self.transport.hosts.first
          if host_hash
            attributes['db.net.peer.name'] = host_hash[:host]
            attributes['db.net.peer.port'] = host_hash[:port]
          end

          # TODO: do we want to parse method/path to improve span naming?
          # TODO: normalize path to reduce cardinality
          span_name = "Elasticsearch #{method} #{path}"

          if config[:create_es_spans]
            tracer.in_span(span_name, attributes: attributes) do |span|
              super
            end
          else
            OpenTelemetry::Common::HTTP::ClientContext.with_attributes(attributes) do
              super
            end
          end
        end

        def tracer
          OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance.tracer
        end

        def config
          OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance.config
        end
      end
    end
  end
end
