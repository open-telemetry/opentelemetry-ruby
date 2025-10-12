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
          private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT)

          ERROR_MESSAGE_INVALID_HEADERS = 'headers must be a String with comma-separated URL Encoded UTF-8 k=v pairs or a Hash'
          private_constant(:ERROR_MESSAGE_INVALID_HEADERS)

          def initialize(endpoint: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT', 'OTEL_EXPORTER_OTLP_ENDPOINT', default: 'http://localhost:4318/v1/traces'),
                         certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                         client_certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                         client_key_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY', 'OTEL_EXPORTER_OTLP_CLIENT_KEY'),
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

            @http = http_connection(@uri, ssl_verify_mode, certificate_file, client_certificate_file, client_key_file)

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
            OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#export: Called with #{span_data.size} spans, timeout=#{timeout.inspect}")
            return OpenTelemetry::SDK::Trace::Export.failure(message: 'exporter is shutdown') if @shutdown

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

          def http_connection(uri, ssl_verify_mode, certificate_file, client_certificate_file, client_key_file)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.verify_mode = ssl_verify_mode
            http.ca_file = certificate_file unless certificate_file.nil?
            http.cert = OpenSSL::X509::Certificate.new(File.read(client_certificate_file)) unless client_certificate_file.nil?
            http.key = OpenSSL::PKey::RSA.new(File.read(client_key_file)) unless client_key_file.nil?
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
            OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Entry with bytes.nil?=#{bytes.nil?}, timeout=#{timeout.inspect}")
            if bytes.nil?
              OpenTelemetry.logger.error('OTLP::HTTP::TraceExporter: send_bytes called with nil bytes')
              return OpenTelemetry::SDK::Trace::Export.failure(message: 'send_bytes called with nil bytes')
            end

            OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Uncompressed size=#{bytes.bytesize} bytes")
            retry_count = 0
            timeout ||= @timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Starting request to #{@uri} with timeout=#{timeout}s")
            around_request do # rubocop:disable Metrics/BlockLength
              request = Net::HTTP::Post.new(@path)
              request.body = if @compression == 'gzip'
                               request.add_field('Content-Encoding', 'gzip')
                               compressed = Zlib.gzip(bytes)
                               OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Compressed size=#{compressed.bytesize} bytes")
                               compressed
                             else
                               OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: No compression applied")
                               bytes
                             end
              request.add_field('Content-Type', 'application/x-protobuf')
              @headers.each { |key, value| request.add_field(key, value) }

              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Remaining timeout=#{remaining_timeout}s, retry_count=#{retry_count}")
              if remaining_timeout.zero?
                OpenTelemetry.logger.error('OTLP::HTTP::TraceExporter: timeout exceeded before sending request')
                return OpenTelemetry::SDK::Trace::Export.failure(message: 'timeout exceeded before sending request')
              end

              @http.open_timeout = remaining_timeout
              @http.read_timeout = remaining_timeout
              @http.write_timeout = remaining_timeout
              @http.start unless @http.started?
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Sending HTTP request")
              response = measure_request_duration { @http.request(request) }
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Received response code=#{response.code}, message=#{response.message}")

              case response
              when Net::HTTPOK
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: SUCCESS - HTTP 200 OK")
                response.body # Read and discard body
                SUCCESS
              when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
                body = response.body
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: ServiceUnavailable/TooManyRequests - retry_count=#{retry_count + 1}, retry_after=#{response['Retry-After']}")
                redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: FAILURE after max retries - HTTP #{response.code}")
                OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed with #{response.code} after #{retry_count} retries")
                OpenTelemetry::SDK::Trace::Export.failure(message: "export failed with HTTP #{response.code} (#{response.message}) after #{retry_count} retries: #{body}")
              when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
                body = response.body
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Timeout/Gateway error - retry_count=#{retry_count + 1}, code=#{response.code}")
                redo if backoff?(retry_count: retry_count += 1, reason: response.code)
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: FAILURE after max retries - HTTP #{response.code}")
                OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed with #{response.code} after #{retry_count} retries")
                OpenTelemetry::SDK::Trace::Export.failure(message: "export failed with HTTP #{response.code} (#{response.message}) after #{retry_count} retries: #{body}")
              when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
                body = response.body
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Client/Server error - HTTP #{response.code}")
                log_status(body)
                @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => response.code })
                OpenTelemetry::SDK::Trace::Export.failure(message: "export failed with HTTP #{response.code} (#{response.message}): #{body}")
              when Net::HTTPRedirection
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Redirect to location=#{response['location']}")
                @http.finish
                handle_redirect(response['location'])
                redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
              else
                OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Unexpected response - code=#{response.code}, class=#{response.class}")
                @http.finish
                body = response.body
                OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed with unexpected HTTP response #{response.code}")
                OpenTelemetry::SDK::Trace::Export.failure(message: "export failed with unexpected HTTP response #{response.code} (#{response.message}): #{body}")
              end
            rescue Net::OpenTimeout, Net::ReadTimeout => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught #{e.class}: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for #{e.class}")
              OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed due to #{e.class} after #{retry_count} retries")
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: "export failed due to #{e.class} after #{retry_count} retries")
            rescue OpenSSL::SSL::SSLError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught SSLError: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for SSLError")
              OpenTelemetry.handle_error(exception: e, message: 'SSL error in OTLP::Exporter#send_bytes')
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: 'SSL error in OTLP::Exporter#send_bytes')
            rescue SocketError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught SocketError: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for SocketError")
              OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed due to SocketError after #{retry_count} retries: #{e.message}")
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: "export failed due to SocketError after #{retry_count} retries: #{e.message}")
            rescue SystemCallError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught #{e.class}: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for #{e.class}")
              OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed due to #{e.class} after #{retry_count} retries: #{e.message}")
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: "export failed due to #{e.class} after #{retry_count} retries: #{e.message}")
            rescue EOFError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught EOFError: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for EOFError")
              OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed due to EOFError after #{retry_count} retries: #{e.message}")
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: "export failed due to EOFError after #{retry_count} retries: #{e.message}")
            rescue Zlib::DataError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught Zlib::DataError: #{e.message}, retry_count=#{retry_count + 1}")
              retry if backoff?(retry_count: retry_count += 1, reason: 'zlib_error')
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Max retries exceeded for Zlib::DataError")
              OpenTelemetry.logger.error("OTLP::HTTP::TraceExporter: export failed due to Zlib::DataError after #{retry_count} retries: #{e.message}")
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: "export failed due to Zlib::DataError after #{retry_count} retries: #{e.message}")
            rescue StandardError => e
              OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Caught unexpected #{e.class}: #{e.message}")
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#send_bytes')
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => e.class.to_s })
              return OpenTelemetry::SDK::Trace::Export.failure(error: e, message: 'unexpected error in OTLP::Exporter#send_bytes')
            end
          ensure
            # Reset timeouts to defaults for the next call.
            OpenTelemetry.logger.debug("OTLP::HTTP::TraceExporter#send_bytes: Resetting timeouts to default #{@timeout}s")
            @http.open_timeout = @timeout
            @http.read_timeout = @timeout
            @http.write_timeout = @timeout
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
