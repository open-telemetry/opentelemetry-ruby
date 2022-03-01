# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HttpClient
      module Patches
        # Module to prepend to HTTPClient for instrumentation
        module Client
          include Common::HTTP::RequestAttributes

          private

          def do_get_block(req, proxy, conn, &block)
            uri = req.header.request_uri
            request_method = req.header.request_method

            attributes = from_request(method: request_method, config: config, uri: uri)

            tracer.in_span("HTTP #{request_method}", attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.header)
              super.tap do
                response = conn.pop
                annotate_span_with_response!(span, response)
                conn.push response
              end
            end
          end

          def annotate_span_with_response!(span, response)
            return unless response&.status_code

            status_code = response.status_code.to_i

            span.set_attribute('http.status_code', status_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(status_code.to_i)
          end

          def tracer
            HttpClient::Instrumentation.instance.tracer
          end

          def config
            HttpClient::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
