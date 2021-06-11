# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module RestClient
      module Patches
        # Module to prepend to RestClient::Request for instrumentation
        module Request
          def execute(&block)
            trace_request do |_span|
              super(&block)
            end
          end

          private

          def trace_request # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
            http_method = method.upcase
            instrumentation_attrs = {
              'http.method' => http_method,
              'http.url' => OpenTelemetry::Common::Utilities.cleanse_url(url)
            }
            config = RestClient::Instrumentation.instance.config
            instrumentation_attrs['peer.service'] = config[:peer_service] if config[:peer_service]
            span = tracer.start_span(
              "HTTP #{http_method}",
              attributes: instrumentation_attrs.merge(
                OpenTelemetry::Common::HTTP::ClientContext.attributes
              ),
              kind: :client
            )

            OpenTelemetry::Trace.with_span(span) do
              OpenTelemetry.propagation.inject(processed_headers)
            end

            yield(span).tap do |response|
              # Verify return value is a response.
              # If so, add additional attributes.
              if response.is_a?(::RestClient::Response)
                span.set_attribute('http.status_code', response.code)
                span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response.code.to_i)
              end
            end
          rescue ::RestClient::ExceptionWithResponse => e
            span.set_attribute('http.status_code', e.http_code)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(e.http_code.to_i)

            raise e
          ensure
            span.finish
          end

          def tracer
            RestClient::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
