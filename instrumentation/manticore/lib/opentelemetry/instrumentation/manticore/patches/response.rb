# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Manticore
      module Patches
        # Module to prepend to RestClient::Request for instrumentation
        module Response

          # Hooks into the #.call function which is executed for any verbs like:
          #   [:get, :post, :put, :options, :header]
          # @api #.call_with_otel_trace! - is the entry point to creating the OpenTelemetry
          #   traces and spans if the class is loaded.
          # it has direct to Manticore::Response methods and instance variables.
          # Take great care of any unintentional mutations:
          # [@request, @response, .on_complete] - are being invoked directly from Manticore::Response
          def call_with_otel_trace!
            wrapped_request = OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.new(@request)
            merged_attr = request_attr(wrapped_request)
                            .merge(header_attr(wrapped_request.headers))
                            .merge(OpenTelemetry::Common::HTTP::ClientContext.attributes)
            span = tracer.start_span("HTTP #{wrapped_request.method}", attributes: merged_attr, kind: :client)
            OpenTelemetry::Trace.with_span(span) do
              OpenTelemetry.propagation.inject(wrapped_request)
            end
            on_complete do |response|
              process_resp_attr(span, OpenTelemetry::Instrumentation::Manticore::Util::WrappedResponse.new(response))
            end
            call_without_otel_trace!
          rescue ::Manticore::ManticoreException => e
            span.set_attribute('http.response.status_code', 500)
            span.set_attribute('http.response.status_text', 'Internal Server Error')
            span.set_attribute('http.response.exception', e.message)
            span.status = OpenTelemetry::Trace::Status.http_to_status(500)
          ensure
            span.finish
          end

          private

          # @param [OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest] wrapped_request A request object that contains
          #   information of an HTTP call to be made
          # @return [Hash] returns request attributes to be added to span
          def request_attr(wrapped_request)
            uri = URI.parse(wrapped_request.uri)
            attr = {
              'library' => 'Manticore',
              'component' => 'http',
              'http.method' => wrapped_request.method,
              'http.host' => uri.host
            }
            attr['http.path'] = uri.path unless uri.path.empty?
            attr['http.query'] = uri.query if uri.query
            attr
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error while fetching request attributes: #{e}",)
            {}
          end

          # @param [OpenTelemetry::Trace::Tracer.in_span] span A running span that has not been completed
          # @param [OpenTelemetry::Instrumentation::Manticore::Util::WrappedResponse] response A wrapped response with limited exposed methods.
          def process_resp_attr(span, response)
            attr = {
              'http.response.status_code' => response.status_code,
              'http.response.status_text' => response.status_text
            }
            if Manticore::Instrumentation.instance.config[:record_all_response_headers]
              response.headers.each { |k, v| attr["http.response.#{k}"] = v unless v.nil? }
            end
            span.add_attributes(attr)
            span.status = OpenTelemetry::Trace::Status.http_to_status(
              response.status_code
            )
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error while adding span attributes #{e}")
          end

          # @param [OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.headers] headers receives the headers hash of the manticore request object
          # @return [Hash] A duplicated headers attributes hash with sanitized values for security reasons.
          def header_attr(headers)
            return {} if headers.empty?
            return {} unless Manticore::Instrumentation.instance.config[:record_all_request_headers]
            attr = {}
            sanitize_headers = Manticore::Instrumentation.instance.config[:sanitize_headers]
            headers.keys.each do |key|
              key_s = key.to_s
              attr["http.headers.#{key_s}"] = sanitize_headers.include?(key_s.downcase) ? '<removed>' : headers[key]
            end
            attr
          end

          def tracer
            Manticore::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
