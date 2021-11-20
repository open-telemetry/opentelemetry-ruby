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
          # Executes for async and sync requests.
          # It has direct to Manticore::Response methods and instance variables.
          # Take great care of any unintentional mutations:
          # [@request, @response, .on_complete] - are being invoked directly from Manticore::Response
          def call
            wrapped_request = OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.new(@request)
            attributes = request_attributes(wrapped_request).merge(OpenTelemetry::Common::HTTP::ClientContext.attributes)
            span = tracer.start_span("HTTP #{wrapped_request.method}", attributes: attributes, kind: :client)
            OpenTelemetry::Trace.with_span(span) do
              OpenTelemetry.propagation.inject(wrapped_request)
            end
            on_complete do |response|
              annotate_span_with_response!(span, response)
            end
            # .super() somehow becomes missing for async requests. Below works for sync and async requests.
            self.method(:call).super_method.call
          rescue ::Manticore::ManticoreException => e
            span.set_attribute('http.status_code', 500)
            span.set_attribute('http.status_text', 'Internal Server Error')
            span.set_attribute('http.exception', e.message)
            span.status = OpenTelemetry::Trace::Status.error
          ensure
            span.finish
          end

          private

          # @param [OpenTelemetry::Trace::Tracer.start_span] span A running span that has not been completed
          # @param [Manticore::Response] response A @response instance object after an outgoing call is attempted
          def annotate_span_with_response!(span, response)
            attr = response_attributes(response)
            span.add_attributes(attr)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response.code)
          end

          # @param [OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest] wrapped_request A WrappedRequest object that exposes some useful methods.
          # @return [Hash] returns request attributes to be added to span
          def request_attributes(wrapped_request)
            uri = URI.parse(wrapped_request.uri)
            attr = {
              'library' => 'Manticore',
              'http.method' => wrapped_request.method,
              'http.scheme' => uri.scheme,
              'http.target' => uri.path,
              'http.url' => "#{uri.scheme}://#{uri.host}",
              'net.peer.name' => uri.host,
              'net.peer.port' => uri.port
            }
            return attr if Manticore::Instrumentation.instance.config["record_request_headers_list"].empty?
            header_attr = header_attributes(wrapped_request.headers,
                                            Manticore::Instrumentation.instance.config["record_request_headers_list"],
                                            'http.request')
            attr.merge(header_attr)
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error while fetching request attributes: #{e}",)
            {}
          end

          # @param [Manticore::Response] response A @response instance object after an outgoing call is attempted
          # @return [Hash] returns response attributes to be added to span.
          def response_attributes(response)
            attr = {
              'http.status_code' => response.code,
              'http.status_text' => response.message
            }
            return attr if Manticore::Instrumentation.instance.config["record_response_headers_list"].empty?
            header_attr = header_attributes(response.headers,
                                            Manticore::Instrumentation.instance.config["record_response_headers_list"],
                                            'http.response')
            attr.merge(header_attr)
          end

          # @param [OpenTelemetry::Instrumentation::Manticore::Util::WrappedRequest.headers] headers receives the headers hash of the manticore request object
          # @param [Array] record_headers_list an array that should include a list of interested headers that would like to be recorded. The headers provided should be from either 'record_response_headers_list' or 'record_request_headers_list' configured when starting the instrumentation installation.
          # @param [String] request_type a string that prefix of all the keys to be recorded in the attribute. The string should only be 'http.request' or 'http.response' This is specified in
          # `https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/trace/semantic_conventions/http.md#http-request-and-response-headers`.
          # @return [Hash] A duplicated headers attributes hash to be added to the span
          def header_attributes(headers, record_headers_list = [], request_type = 'http.request')
            return {} if headers.empty? || record_headers_list.empty?
            attr = {}
            record_list = headers.keys & record_headers_list
            record_list.each do |key|
              attr["#{request_type}.#{key}"] = headers[key]
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
