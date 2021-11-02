# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTP
      module Patches
        # Module to prepend to HTTP::Client for instrumentation
        module Client
          def perform(req, options) # rubocop:disable Metrics/AbcSize
            uri = req.uri
            request_method = req.verb.to_s.upcase

            attributes = {
              'http.method' => request_method,
              'http.scheme' => uri.scheme,
              'http.target' => uri.path,
              'http.url' => "#{uri.scheme}://#{uri.host}",
              'net.peer.name' => uri.host,
              'net.peer.port' => uri.port
            }.merge(OpenTelemetry::Common::HTTP::ClientContext.attributes)

            tracer.in_span("HTTP #{request_method}", attributes: attributes, kind: :client) do |span|
              OpenTelemetry.propagation.inject(req.headers)
              super.tap do |response|
                annotate_span_with_response!(span, response)
              end
            end
          end

          private

          def annotate_span_with_response!(span, response)
            return unless response&.status

            status_code = response.status.to_i
            span.set_attribute('http.status_code', status_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(status_code.to_i)
          end

          def tracer
            HTTP::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
