# frozen_string_literal: true

# Copyright 2020 OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Adapters
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

              tracer.in_span(
                HTTP_METHODS_TO_SPAN_NAMES[req.method],
                attributes: {
                  'component' => 'http',
                  'http.method' => req.method,
                  'http.scheme' => USE_SSL_TO_SCHEME[use_ssl?],
                  'http.target' => req.path,
                  'peer.hostname' => @address,
                  'peer.port' => @port
                },
                kind: :client
              ) do |span|
                OpenTelemetry.propagation.inject(req)

                super(req, body, &block).tap do |response|
                  annotate_span_with_response!(span, response)
                end
              end
            end

            private

            def annotate_span_with_response!(span, response)
              return unless response&.code

              status_code = response.code.to_i

              span.set_attribute('http.status_code', status_code)
              span.status = OpenTelemetry::Trace::Status.http_to_status(
                status_code
              )
            end

            def tracer
              Net::HTTP::Adapter.instance.tracer
            end
          end
        end
      end
    end
  end
end
