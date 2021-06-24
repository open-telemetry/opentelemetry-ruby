# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        module Patches
          # Module to prepend to Net::HTTP for instrumentation
          module Instrumentation
            HTTP_METHODS_TO_SPAN_NAMES = Hash.new { |h, k| h[k] = "HTTP #{k}" }
            USE_SSL_TO_SCHEME = { false => 'http', true => 'https' }.freeze

            def request(req, body = nil, &block)
              # Do not trace recursive call for starting the connection
              return super(req, body, &block) unless started?

              attributes = OpenTelemetry::Common::HTTP::ClientContext.attributes
              tracer.in_span(
                HTTP_METHODS_TO_SPAN_NAMES[req.method],
                attributes: attributes.merge(
                  'http.method' => req.method,
                  'http.scheme' => USE_SSL_TO_SCHEME[use_ssl?],
                  'http.target' => req.path,
                  'peer.hostname' => @address,
                  'peer.port' => @port
                ),
                kind: :client
              ) do |span|
                OpenTelemetry.propagation.inject(req)

                super(req, body, &block).tap do |response|
                  annotate_span_with_response!(span, response)
                end
              end
            end

            private

            def connect
              if proxy?
                conn_address = proxy_address
                conn_port    = proxy_port
              else
                conn_address = address
                conn_port    = port
              end

              attributes = OpenTelemetry::Common::HTTP::ClientContext.attributes
              tracer.in_span('HTTP CONNECT', attributes: attributes.merge(
                'peer.hostname' => conn_address,
                'peer.port' => conn_port
              )) do
                super
              end
            end

            def annotate_span_with_response!(span, response)
              return unless response&.code

              status_code = response.code.to_i

              span.set_attribute('http.status_code', status_code)
              span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(status_code.to_i)
            end

            def tracer
              Net::HTTP::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
