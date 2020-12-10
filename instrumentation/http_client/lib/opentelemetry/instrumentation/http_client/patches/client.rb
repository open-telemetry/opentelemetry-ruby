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
          def do_request(method, uri, query, body, header, &block)
            url = "#{uri.scheme}://#{uri.host}"

            attributes = {
              'http.method' => method.upcase.to_s,
              'http.scheme' => uri.scheme,
              'http.target' => uri.path,
              'http.url' => url,
              'peer.hostname' => uri.host,
              'peer.port' => uri.port
            }.merge(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span("HTTP #{method.upcase}", attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(header)
              super.tap do |response|
                annotate_span_with_response!(span, response)
              end
            end
          end

          private

          def annotate_span_with_response!(span, response)
            return unless response&.status_code

            status_code = response&.status_code.to_i

            span.set_attribute('http.status_code', status_code)
            span.status = OpenTelemetry::Trace::Status.http_to_status(
              status_code
            )
          end

          def tracer
            HttpClient::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
