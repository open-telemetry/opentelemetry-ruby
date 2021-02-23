# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'

module OpenTelemetry
  module Exporter
    module Zipkin
      # An OpenTelemetry trace exporter that sends spans over HTTP as Thrift Binary encoded Zipkin spans.
      class CollectorExporter
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        TIMEOUT = OpenTelemetry::SDK::Trace::Export::TIMEOUT
        private_constant(:SUCCESS, :FAILURE, :TIMEOUT)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        RETRY_COUNT = 5
        WRITE_TIMEOUT_SUPPORTED = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')
        private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT, :WRITE_TIMEOUT_SUPPORTED)

        def initialize(endpoint: config_opt('OTEL_EXPORTER_ZIPKIN_ENDPOINT', default: 'http://localhost:9411/api/v2/spans'),
                       headers: config_opt('OTEL_EXPORTER_ZIPKIN_TRACES_HEADERS', 'OTEL_EXPORTER_ZIPKIN_HEADERS'),
                       timeout: config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10)
                       )
          raise ArgumentError, "invalid url for Zipkin::Exporter #{endpoint}" if invalid_url?(endpoint)
          raise ArgumentError, 'headers must be comma-separated k=v pairs or a Hash' unless valid_headers?(headers)

          @uri = if endpoint == ENV['OTEL_EXPORTER_ZIPKIN_ENDPOINT']
                   URI("#{endpoint}/api/v2/spans")
                 else
                   URI(endpoint)
                 end

          @http = Net::HTTP.new(@uri.host, @uri.port)
          @http.use_ssl = @uri.scheme == 'https'
          @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

          @path = @uri.path
          @headers = case headers
                     when String then CSV.parse(headers, col_sep: '=', row_sep: ',').to_h
                     when Hash then headers
                     end

          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] the result of the export.
        def export(span_data, timeout: nil)
          return FAILURE if @shutdown

          zipkin_spans = encode_spans(span_data)

          send_spans(zipkin_spans, timeout)

          SUCCESS
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in Jaeger::CollectorExporter#export')
          FAILURE
        end

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
        end

        private

        def config_opt(*env_vars, default: nil)
          env_vars.each do |env_var|
            val = ENV[env_var]
            return val unless val.nil?
          end
          default
        end

        def around_request
          OpenTelemetry::Common::Utilities.untraced { yield }
        end

        def invalid_url?(url)
          return true if url.nil? || url.strip.empty?

          URI(url)
          false
        rescue URI::InvalidURIError
          true
        end

        def send_spans(zipkin_spans, timeout: nil)
          # todo send spans
        end

        def encode_spans(span_data)
          span_data.group_by(&:resource).map do |resource, spans|
            spans.map! { |span| Transformer.to_zipkin_span(span, resource) }
          end
        end
      end
    end
  end
end
