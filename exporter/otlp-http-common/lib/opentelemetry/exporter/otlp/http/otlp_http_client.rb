# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'forwardable'
require 'net/http'
require 'opentelemetry/common'
require 'opentelemetry/exporter/otlp/common'

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # OTLPHTTPClient is a client class for sending OTLP data over HTTP.
        class OTLPHTTPClient # rubocop:disable Metrics/ClassLength
          extend Forwardable

          # Default timeouts in seconds.
          KEEP_ALIVE_TIMEOUT = 30
          RETRY_COUNT = 5
          private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT)

          attr_reader :http, :uri

          def_delegators :@http,
                         :request,
                         :start,
                         :finish,
                         :started?,
                         :active?,
                         :verify_mode,
                         :ca_file,
                         :cert,
                         :key,
                         :use_ssl?,
                         :address,
                         :port,
                         :read_timeout=,
                         :read_timeout,
                         :write_timeout=,
                         :write_timeout,
                         :open_timeout=,
                         :open_timeout

          def initialize(options, service, base_path = '')
            if options.nil?
              @options = OpenTelemetry::Exporter::OTLP::HTTP::OtlpHttpExporterConfig.new.load_from_env(service)
              @uri = OpenTelemetry::Exporter::OTLP::Common::Utilities.build_uri(nil, base_path, "OTEL_EXPORTER_OTLP_#{service}_ENDPOINT", 'OTEL_EXPORTER_OTLP_ENDPOINT', 'http://localhost:4318/')
            else
              @options = options
              @options.endpoint ||= "http://localhost:4318/#{base_path}"
              raise ArgumentError, "invalid url for OTLPHttp#{service}Exporter #{options.endpoint} set via config" unless OpenTelemetry::Common::Utilities.valid_url?(options.endpoint)

              @uri = URI(@options.endpoint)
            end

            raise ArgumentError, "unsupported compression key #{@options.compression}" unless @options.compression.nil? || %w[gzip none].include?(@options.compression)

            @http = Net::HTTP.new(@uri.hostname, @uri.port)
            @http.use_ssl = @uri.scheme == 'https'
            @http.verify_mode = @options.ssl_verify_mode
            @http.ca_file = @options.tls.ca_file if @options.tls.ca_file
            @http.cert = OpenSSL::X509::Certificate.new(File.read(@options.tls.cert_file)) if @options.tls.cert_file
            @http.key = OpenSSL::PKey::RSA.new(File.read(@options.tls.key_file)) if @options.tls.key_file
            @http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT

            set_user_agent(@options.headers, "OTel-OTLP-HTTP-#{service}-Exporter-Ruby/#{OpenTelemetry::Exporter::OTLP::HTTP::Common::VERSION}")
          end

          # export_bytes is a method that sends the given bytes to the configured endpoint. It returns an ExportResult object indicating success or failure.
          def export_bytes(bytes, timeout: nil) # rubocop:disable Metrics/MethodLength
            return ExportResult.new(success: false) if bytes.nil?

            retry_count = 0
            timeout ||= @options.timeout
            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            around_request do
              request = Net::HTTP::Post.new(@uri.path)
              body = if @options.compression == 'gzip'
                       request.add_field('Content-Encoding', 'gzip')
                       Zlib.gzip(bytes)
                     else
                       bytes
                     end
              request.body = body
              request.add_field('Content-Type', 'application/x-protobuf')
              @options.headers.each { |header| request.add_field(header[:name], header[:value]) }

              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return ExportResult.new(success: false) if remaining_timeout.zero?

              @http.open_timeout = remaining_timeout
              @http.read_timeout = remaining_timeout
              @http.write_timeout = remaining_timeout
              @http.start unless @http.started?
              response = @http.request(request)

              case response
              when Net::HTTPSuccess
                response.body # Read and discard body
                ExportResult.new(success: true)
              when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
                response.body # Read and discard body
                redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
                ExportResult.new(success: false, http_response_code: response.code)
              when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
                response.body # Read and discard body
                redo if backoff?(retry_count: retry_count += 1, reason: response.code)
                ExportResult.new(success: false, http_response_code: response.code)
              when Net::HTTPNotFound
                log_request_failure(response.code)
                ExportResult.new(success: false, http_response_code: response.code)
              when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
                ExportResult.new(success: false, http_response_code: response.code, http_response_body: response.body)
              when Net::HTTPRedirection
                @http.finish
                handle_redirect(response['location'])
                redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
              else
                @http.finish
                ExportResult.new(success: false)
              end
            rescue Net::OpenTimeout, Net::ReadTimeout
              retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
              return ExportResult.new(success: false)
            rescue OpenSSL::SSL::SSLError => e
              retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
              OpenTelemetry.handle_error(exception: e, message: 'SSL error in OTLP::Exporter#send_bytes')
              return ExportResult.new(success: false)
            rescue SocketError
              retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
              return ExportResult.new(success: false)
            rescue SystemCallError => e
              retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
              return ExportResult.new(success: false)
            rescue EOFError
              retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
              return ExportResult.new(success: false)
            rescue Zlib::DataError
              retry if backoff?(retry_count: retry_count += 1, reason: 'zlib_error')
              return ExportResult.new(success: false)
            rescue StandardError => e
              OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#send_bytes')
              return ExportResult.new(success: false)
            end
          ensure
            # Reset timeouts to defaults for the next call.
            @http.open_timeout = @timeout
            @http.read_timeout = @timeout
            @http.write_timeout = @timeout
          end

          private

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

          def backoff?(retry_count:, reason:, retry_after: nil)
            OpenTelemetry.handle_error(message: "OTLP exporter backing off due to: #{reason}")
            return false if retry_count > RETRY_COUNT

            sleep_interval = nil
            unless retry_after.nil?
              sleep_interval =
                Integer(retry_after, exception: false)
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

          def handle_redirect(location)
            # TODO: figure out destination and reinitialize @http and @path
          end

          def log_request_failure(response_code)
            OpenTelemetry.handle_error(message: "OTLP exporter received http.code=#{response_code} for uri='#{@uri}' in OTLP::Exporter#send_bytes")
          end

          def set_user_agent(headers, value_to_append)
            existing = headers.find { |h| h[:name].casecmp?('User-Agent') }

            if existing
              existing[:value] = "#{existing[:value]} #{value_to_append}".strip
            else
              headers << { name: 'User-Agent', value: value_to_append }
            end
          end
        end
      end
    end
  end
end
