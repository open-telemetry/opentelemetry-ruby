# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'uri'
require 'opentelemetry/common'
require 'opentelemetry/sdk'
require 'net/http'
require 'csv'
require 'json'

module OpenTelemetry
  module Exporter
    module Zipkin
      # An OpenTelemetry trace exporter that sends spans over HTTP as JSON encoded Zipkin spans.
      class Exporter # rubocop:disable Metrics/ClassLength
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        TIMEOUT = OpenTelemetry::SDK::Trace::Export::TIMEOUT
        private_constant(:SUCCESS, :FAILURE, :TIMEOUT)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        RETRY_COUNT = 5
        private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT)

        def initialize(endpoint: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_ZIPKIN_ENDPOINT', default: 'http://localhost:9411/api/v2/spans'),
                       headers: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_ZIPKIN_TRACES_HEADERS', 'OTEL_EXPORTER_ZIPKIN_HEADERS'),
                       timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_ZIPKIN_TRACES_TIMEOUT', 'OTEL_EXPORTER_ZIPKIN_TIMEOUT', default: 10),
                       metrics_reporter: nil)
          raise ArgumentError, "invalid url for Zipkin::Exporter #{endpoint}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)
          raise ArgumentError, 'headers must be comma-separated k=v pairs or a Hash' unless valid_headers?(headers)

          @uri = if endpoint == ENV['OTEL_EXPORTER_ZIPKIN_ENDPOINT']
                   URI("#{endpoint}/api/v2/spans")
                 else
                   URI(endpoint)
                 end

          @http = Net::HTTP.new(@uri.host, @uri.port)
          @http.use_ssl = @uri.scheme == 'https'
          @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

          @timeout = timeout.to_f
          @path = @uri.path
          @headers = case headers
                     when String then CSV.parse(headers, col_sep: '=', row_sep: ',').to_h
                     when Hash then headers
                     end

          @metrics_reporter = metrics_reporter || OpenTelemetry::SDK::Trace::Export::MetricsReporter
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
          send_spans(zipkin_spans, timeout: timeout)
        rescue StandardError => e
          @metrics_reporter.add_to_counter('otel.zipkin_exporter.failure', labels: { 'reason' => e.class.to_s })
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in Zipkin::Exporter#export')
          FAILURE
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def force_flush(timeout: nil)
          SUCCESS
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}

        # Called when {OpenTelemetry::SDK::Trace::Tracer#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::Tracer}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
          SUCCESS
        end

        private

        def encode_spans(span_data)
          span_data.map! { |span| Transformer.to_zipkin_span(span, span.resource) }
        end

        def around_request
          OpenTelemetry::Common::Utilities.untraced { yield }
        end

        def valid_headers?(headers)
          return true if headers.nil? || headers.is_a?(Hash)
          return false unless headers.is_a?(String)

          CSV.parse(headers, col_sep: '=', row_sep: ',').to_h
          true
        rescue ArgumentError
          false
        end

        def send_spans(zipkin_spans, timeout: nil) # rubocop:disable Metrics/MethodLength
          retry_count = 0
          timeout ||= @timeout
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          around_request do # rubocop:disable Metrics/BlockLength
            request = Net::HTTP::Post.new(@path)
            request.body = JSON.generate(zipkin_spans)
            request.add_field('Content-Type', 'application/json')
            @headers&.each { |key, value| request.add_field(key, value) }

            remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
            return TIMEOUT if remaining_timeout.zero?

            @http.open_timeout = remaining_timeout
            @http.read_timeout = remaining_timeout
            @http.write_timeout = remaining_timeout
            @http.start unless @http.started?

            response = measure_request_duration { @http.request(request) }
            response.body # Read and discard body
            # in opentelemetry-js 200-399 is success, in opentelemetry-collector zipkin exporter,200-299 is a success
            # zipkin api docs list 202 as default success code
            # https://zipkin.io/zipkin-api/#/default/post_spans
            # TODO: redirect

            case response
            when Net::HTTPAccepted, Net::HTTPOK
              response.body # Read and discard body
              SUCCESS
            when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
              response.body # Read and discard body
              redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
              response.body # Read and discard body
              redo if backoff?(retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
              # TODO: decode the body as a google.rpc.Status Protobuf-encoded message when https://github.com/open-telemetry/opentelemetry-collector/issues/1357 is fixed.
              response.body # Read and discard body
              FAILURE
            when Net::HTTPRedirection
              @http.finish
              handle_redirect(response['location'])
              redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
            else
              @http.finish
              FAILURE
            end
          rescue Net::OpenTimeout, Net::ReadTimeout
            retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
            return FAILURE
          end
        end

        def handle_redirect(location)
          # TODO: figure out destination and reinitialize @http and @path
        end

        def backoff?(retry_count:, reason:, retry_after: nil)
          return false if retry_count > RETRY_COUNT

          # TODO: metric exporter

          sleep_interval = nil
          unless retry_after.nil?
            sleep_interval =
              begin
                Integer(retry_after)
              rescue ArgumentError
                nil
              end
            sleep_interval ||=
              begin
                Time.httpdate(retry_after) - Time.now
              rescue # rubocop:disable Style/RescueStandardError
                nil
              end
            sleep_interval = nil unless sleep_interval&.positive?
          end
          sleep_interval ||= rand(2**retry_count)

          sleep(sleep_interval)
          true
        end

        def measure_request_duration
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            response = yield
          ensure
            stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            duration_ms = 1000.0 * (stop - start)
            @metrics_reporter.record_value('otel.zipkin_exporter.request_duration',
                                           value: duration_ms,
                                           labels: { 'status' => response&.code || 'unknown' })
          end
        end
      end
    end
  end
end
