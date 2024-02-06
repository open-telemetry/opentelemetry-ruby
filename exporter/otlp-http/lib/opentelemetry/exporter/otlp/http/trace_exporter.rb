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

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
        class TraceExporter # rubocop:disable Metrics/ClassLength
          SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
          FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
          private_constant(:SUCCESS, :FAILURE)

          # Default timeouts in seconds.
          KEEP_ALIVE_TIMEOUT = 30
          RETRY_COUNT = 5
          WRITE_TIMEOUT_SUPPORTED = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6')
          private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT, :WRITE_TIMEOUT_SUPPORTED)

          ERROR_MESSAGE_INVALID_HEADERS = 'headers must be a String with comma-separated URL Encoded UTF-8 k=v pairs or a Hash'
          private_constant(:ERROR_MESSAGE_INVALID_HEADERS)

          def initialize(endpoint: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'http://localhost:4318/v1/traces'),
                         certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                         ssl_verify_mode: fetch_ssl_verify_mode,
                         headers: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_HEADERS', 'OTEL_EXPORTER_OTLP_HEADERS', default: {}),
                         compression: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', 'OTEL_EXPORTER_OTLP_COMPRESSION', default: 'gzip'),
                         timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                         metrics_reporter: nil)
            raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}" unless OpenTelemetry::Common::Utilities.valid_url?(endpoint)
            raise ArgumentError, "unsupported compression key #{compression}" unless compression.nil? || %w[gzip none].include?(compression)

            @uri = if endpoint == ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
                     URI("#{endpoint}/v1/traces")
                   else
                     URI(endpoint)
                   end

            @http = http_connection(@uri, ssl_verify_mode, certificate_file)

            @path = @uri.path
            @headers = case headers
                       when String then parse_headers(headers)
                       when Hash then headers
                       else
                         raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
                       end
            @timeout = timeout.to_f
            @compression = compression
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

            send_bytes(OpenTelemetry::Exporter::OTLP::Common.as_encoded_etsr(span_data), timeout: timeout)
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
          # object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          def shutdown(timeout: nil)
            @shutdown = true
            @http.finish if @http.started?
            SUCCESS
          end

          private

          def fetch_ssl_verify_mode
            if ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER')
              OpenSSL::SSL::VERIFY_PEER
            elsif ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE')
              OpenSSL::SSL::VERIFY_NONE
            else
              OpenSSL::SSL::VERIFY_PEER
            end
          end

          def http_connection(uri, ssl_verify_mode, certificate_file)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.verify_mode = ssl_verify_mode
            http.ca_file = certificate_file unless certificate_file.nil?
            http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
            http
          end

          # The around_request is a private method that provides an extension
          # point for the exporters network calls. The default behaviour
          # is to not trace these operations.
          #
          # An example use case would be to prepend a patch, or extend this class
          # and override this method's behaviour to explicitly trace the HTTP request.
          # This would allow you to trace your export pipeline.
          def around_request
            OpenTelemetry::Common::Utilities.untraced { yield } # rubocop:disable Style/ExplicitBlockArgument
          end

          def send_bytes(bytes, timeout:) # rubocop:disable Metrics/MethodLength
            return FAILURE if bytes.nil?

            retry_count = 0
            timeout ||= @timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            around_request do # rubocop:disable Metrics/BlockLength
              request = Net::HTTP::Post.new(@path)
              request.body = if @compression == 'gzip'
                               request.add_field('Content-Encoding', 'gzip')
                               Zlib.gzip(bytes)
                             else
                               bytes
                             end
              request.add_field('Content-Type', 'application/x-protobuf')
              @headers.each { |key, value| request.add_field(key, value) }

              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return FAILURE if remaining_timeout.zero?

              @http.open_timeout = remaining_timeout
              @http.read_timeout = remaining_timeout
              @http.write_timeout = remaining_timeout if WRITE_TIMEOUT_SUPPORTED
              @http.start unless @http.started?
              response = measure_request_duration { @http.request(request) }

              case response
              when Net::HTTPOK
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
                log_status(response.body)
                @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => response.code })
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
            rescue OpenSSL::SSL::SSLError
              retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
              return FAILURE
            rescue SocketError
              retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
              return FAILURE
            rescue SystemCallError => e
              retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
              return FAILURE
            rescue EOFError
              retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
              return FAILURE
            rescue Zlib::DataError
              retry if backoff?(retry_count: retry_count += 1, reason: 'zlib_error')
              return FAILURE
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#send_bytes')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => e.class.to_s })
              return FAILURE
            end
          ensure
            # Reset timeouts to defaults for the next call.
            @http.open_timeout = @timeout
            @http.read_timeout = @timeout
            @http.write_timeout = @timeout if WRITE_TIMEOUT_SUPPORTED
          end

          def handle_redirect(location)
            # TODO: figure out destination and reinitialize @http and @path
          end

          def log_status(body)
            status = Google::Rpc::Status.decode(body)
            details = status.details.map do |detail|
              klass_or_nil = ::Google::Protobuf::DescriptorPool.generated_pool.lookup(detail.type_name).msgclass
              detail.unpack(klass_or_nil) if klass_or_nil
            end.compact
            OpenTelemetry.handle_error(message: "OTLP exporter received rpc.Status{message=#{status.message}, details=#{details}}")
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error decoding rpc.Status in OTLP::Exporter#log_status')
          end

          def measure_request_duration
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            begin
              response = yield
            ensure
              stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              duration_ms = 1000.0 * (stop - start)
              @metrics_reporter.record_value('otel.otlp_exporter.request_duration',
                                             value: duration_ms,
                                             labels: { 'status' => response&.code || 'unknown' })
            end
          end

          def backoff?(retry_count:, reason:, retry_after: nil)
            @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => reason })
            return false if retry_count > RETRY_COUNT

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

          def parse_headers(raw)
            entries = raw.split(',')
            raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if entries.empty?

            entries.each_with_object({}) do |entry, headers|
              k, v = entry.split('=', 2).map(&CGI.method(:unescape))
              begin
                k = k.to_s.strip
                v = v.to_s.strip
              rescue Encoding::CompatibilityError
                raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
              rescue ArgumentError => e
                raise e, ERROR_MESSAGE_INVALID_HEADERS
              end
              raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if k.empty? || v.empty?

              headers[k] = v
            end
          end
        end
      end
    end
  end
end
