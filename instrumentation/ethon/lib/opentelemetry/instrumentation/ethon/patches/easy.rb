# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Ethon
      module Patches
        # Ethon::Easy patch for instrumentation
        module Easy
          ACTION_NAMES_TO_HTTP_METHODS = Hash.new do |h, k|
            # #to_s is required because user input could be symbol or string
            h[k] = k.to_s.upcase
          end
          HTTP_METHODS_TO_SPAN_NAMES = Hash.new { |h, k| h[k] = "HTTP #{k}" }

          def http_request(url, action_name, options = {})
            @otel_method = ACTION_NAMES_TO_HTTP_METHODS[action_name]
            super
          end

          def headers=(headers)
            # Store headers to call this method again when span is ready
            @otel_original_headers = headers
            super
          end

          def perform
            otel_before_request
            super
          end

          def complete
            begin
              response_options = mirror.options
              response_code = (response_options[:response_code] || response_options[:code]).to_i
              if response_code.zero?
                return_code = response_options[:return_code]
                message = return_code ? ::Ethon::Curl.easy_strerror(return_code) : 'unknown reason'
                @otel_span.status = OpenTelemetry::Trace::Status.error("Request has failed: #{message}")
              else
                @otel_span.set_attribute('http.status_code', response_code)
                @otel_span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response_code.to_i)
              end
            ensure
              @otel_span&.finish
              @otel_span = nil
            end
            super
          end

          def reset
            super
          ensure
            @otel_span = nil
            @otel_method = nil
            @otel_original_headers = nil
          end

          def otel_before_request
            method = 'N/A' # Could be GET or not HTTP at all
            method = @otel_method if instance_variable_defined?(:@otel_method) && !@otel_method.nil?

            @otel_span = tracer.start_span(
              HTTP_METHODS_TO_SPAN_NAMES[method],
              attributes: span_creation_attributes(method),
              kind: :client
            )

            @otel_original_headers ||= {}
            OpenTelemetry::Trace.with_span(@otel_span) do
              OpenTelemetry.propagation.inject(@otel_original_headers)
            end
            self.headers = @otel_original_headers
          end

          def otel_span_started?
            instance_variable_defined?(:@otel_span) && !@otel_span.nil?
          end

          private

          def span_creation_attributes(method)
            instrumentation_attrs = {
              'http.method' => method,
              'http.url' => OpenTelemetry::Common::Utilities.cleanse_url(url)
            }
            config = Ethon::Instrumentation.instance.config
            instrumentation_attrs['peer.service'] = config[:peer_service] if config[:peer_service]
            instrumentation_attrs.merge(
              OpenTelemetry::Common::HTTP::ClientContext.attributes
            )
          end

          def tracer
            Ethon::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
