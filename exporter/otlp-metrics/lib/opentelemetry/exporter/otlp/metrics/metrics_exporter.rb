# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common'
require 'opentelemetry/sdk'
require 'net/http'
require 'zlib'

require 'google/rpc/status_pb'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/metrics/v1/metrics_pb'
require 'opentelemetry/proto/collector/metrics/v1/metrics_service_pb'

require 'opentelemetry/metrics'
require 'opentelemetry/sdk/metrics'

require_relative 'util'

module OpenTelemetry
  module Exporter
    module OTLP
      module Metrics
        # An OpenTelemetry metrics exporter that sends metrics over HTTP as Protobuf encoded OTLP ExportMetricsServiceRequest.
        class MetricsExporter < ::OpenTelemetry::SDK::Metrics::Export::MetricReader
          include Util

          attr_reader :metric_snapshots

          SUCCESS = OpenTelemetry::SDK::Metrics::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Metrics::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          # rubocop:disable Lint/DuplicateBranch
          # Returns the SSL verify mode configured via environment variables.
          def self.ssl_verify_mode
            if ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER')
              OpenSSL::SSL::VERIFY_PEER
            elsif ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE')
              OpenSSL::SSL::VERIFY_NONE
            else
              OpenSSL::SSL::VERIFY_PEER
            end
          end
          # rubocop:enable Lint/DuplicateBranch

          def initialize(endpoint: nil,
                         certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                         client_certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_CLIENT_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                         client_key_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_CLIENT_KEY', 'OTEL_EXPORTER_OTLP_CLIENT_KEY'),
                         ssl_verify_mode: MetricsExporter.ssl_verify_mode,
                         headers: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_HEADERS', 'OTEL_EXPORTER_OTLP_HEADERS', default: {}),
                         compression: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_COMPRESSION', 'OTEL_EXPORTER_OTLP_COMPRESSION', default: 'gzip'),
                         timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_METRICS_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                         aggregation_cardinality_limit: nil)
            raise ArgumentError, "unsupported compression key #{compression}" unless compression.nil? || %w[gzip none].include?(compression)

            # create the MetricStore object
            super(aggregation_cardinality_limit: aggregation_cardinality_limit)

            @uri = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri(endpoint, 'v1/metrics', 'OTEL_EXPORTER_OTLP_METRICS_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318/')
            @http = http_connection(@uri, ssl_verify_mode, certificate_file, client_certificate_file, client_key_file)

            @path = @uri.path
            @headers = prepare_headers(headers)
            @timeout = timeout.to_f
            @compression = compression
            @mutex = Mutex.new
            @shutdown = false
          end

          # consolidate the metrics data into the form of MetricData
          #
          # return MetricData
          def pull
            export(collect)
          end

          # metrics Array[MetricData]
          def export(metrics, timeout: nil)
            if @shutdown
              OpenTelemetry.logger.warn('Exporter already shutdown, ignoring export request')
              return FAILURE
            end

            @mutex.synchronize do
              send_bytes(OpenTelemetry::Exporter::OTLP::Common.as_encoded_emsr(metrics), timeout: timeout)
            end
          end

          # Sends the encoded request bytes to the configured OTLP endpoint.
          def send_bytes(bytes, timeout:)
            return FAILURE if @shutdown || bytes.nil?

            request = Net::HTTP::Post.new(@path)

            if @compression == 'gzip'
              request.add_field('Content-Encoding', 'gzip')
              body = Zlib.gzip(bytes)
            else
              body = bytes
            end

            request.body = body
            request.add_field('Content-Type', 'application/x-protobuf')
            @headers.each { |key, value| request.add_field(key, value) }

            retry_count = 0
            timeout ||= @timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp

            around_request do
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return FAILURE if remaining_timeout.zero?

              @http.open_timeout = remaining_timeout
              @http.read_timeout = remaining_timeout
              @http.write_timeout = remaining_timeout
              @http.start unless @http.started?
              response = @http.request(request)
              case response
              when Net::HTTPSuccess
                response.body # Read and discard body
                SUCCESS
              when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
                response.body # Read and discard body
                redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
                OpenTelemetry.logger.warn('Net::HTTPServiceUnavailable/Net::HTTPTooManyRequests in MetricsExporter#send_bytes')
                FAILURE
              when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
                response.body # Read and discard body
                redo if backoff?(retry_count: retry_count += 1, reason: response.code)
                OpenTelemetry.logger.warn('Net::HTTPRequestTimeOut/Net::HTTPGatewayTimeOut/Net::HTTPBadGateway in MetricsExporter#send_bytes')
                FAILURE
              when Net::HTTPNotFound
                OpenTelemetry.handle_error(message: "OTLP metrics_exporter received http.code=404 for uri: '#{@path}'")
                FAILURE
              when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
                log_status(response.body)
                OpenTelemetry.logger.warn('Net::HTTPBadRequest/Net::HTTPClientError/Net::HTTPServerError in MetricsExporter#send_bytes')
                FAILURE
              when Net::HTTPRedirection
                @http.finish
                handle_redirect(response['location'])
                redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
              else
                @http.finish
                OpenTelemetry.logger.warn("Unexpected error in OTLP::MetricsExporter#send_bytes - #{response.message}")
                FAILURE
              end
            rescue Net::OpenTimeout, Net::ReadTimeout
              retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
              OpenTelemetry.logger.warn('Net::OpenTimeout/Net::ReadTimeout in MetricsExporter#send_bytes')
              return FAILURE
            rescue OpenSSL::SSL::SSLError
              retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
              OpenTelemetry.logger.warn('OpenSSL::SSL::SSLError in MetricsExporter#send_bytes')
              return FAILURE
            rescue SocketError
              retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
              OpenTelemetry.logger.warn('SocketError in MetricsExporter#send_bytes')
              return FAILURE
            rescue SystemCallError => e
              retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
              OpenTelemetry.logger.warn('SystemCallError in MetricsExporter#send_bytes')
              return FAILURE
            rescue EOFError
              retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
              OpenTelemetry.logger.warn('EOFError in MetricsExporter#send_bytes')
              return FAILURE
            rescue Zlib::DataError
              retry if backoff?(retry_count: retry_count += 1, reason: 'zlib_error')
              OpenTelemetry.logger.warn('Zlib::DataError in MetricsExporter#send_bytes')
              return FAILURE
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::MetricsExporter#send_bytes')
              return FAILURE
            end
          ensure
            # Reset timeouts to defaults for the next call.
            @http.open_timeout = @timeout
            @http.read_timeout = @timeout
            @http.write_timeout = @timeout
          end

          # may not need this
          def reset
            SUCCESS
          end

          # No-op: there is nothing to flush for this exporter.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Marks this exporter as shut down so subsequent exports fail.
          def shutdown(timeout: nil)
            if @shutdown
              OpenTelemetry.logger.warn('Exporter already shutdown, ignoring call')
              return
            end

            @shutdown = true
            super # marks the underlying MetricReader as stopped so subsequent collections fail
            SUCCESS
          end
        end
      end
    end
  end
end
