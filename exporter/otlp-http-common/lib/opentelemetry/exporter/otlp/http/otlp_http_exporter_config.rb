# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Exporter
    module OTLP
      module HTTP
        # OtlpHttpExporterConfig is a configuration class for the OTLP HTTP exporter.
        class OtlpHttpExporterConfig
          ERROR_MESSAGE_INVALID_HEADERS = 'headers must be a String with comma-separated URL Encoded UTF-8 k=v pairs or a Hash'

          attr_reader :tls,
                      :ssl_verify_mode,
                      :endpoint,
                      :compression,
                      :timeout,
                      :headers

          attr_writer :endpoint

          def initialize(
            certificate_file: nil,
            client_certificate_file: nil,
            client_key_file: nil,
            ssl_verify_mode: nil,
            endpoint: nil,
            tls: nil,
            compression: nil,
            timeout: nil,
            headers: nil,
            headers_list: nil
          )
            @tls = tls || OpenTelemetry::Exporter::OTLP::HTTP::HttpTlsConfig.new(ca_file: certificate_file, key_file: client_key_file, cert_file: client_certificate_file)
            @ssl_verify_mode = ssl_verify_mode
            @endpoint = endpoint
            @timeout = (timeout || 10).to_f
            @compression = compression || 'none'

            @headers =
              case headers
              when nil
                []
              when Hash
                headers.map do |key, value|
                  { name: key, value: value }
                end
              when Array
                headers
              when String
                parse_header_string(headers)
              else
                raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
              end

            @headers.concat(parse_headers(headers_list)) if headers_list
          end

          private

          def parse_headers(raw)
            entries = raw.split(',')
            raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if entries.empty?

            entries.map do |entry|
              k, v = entry.split('=', 2).map { |part| URI.decode_uri_component(part) }
              begin
                k = k.to_s.strip
                v = v.to_s.strip
              rescue Encoding::CompatibilityError
                raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
              rescue ArgumentError => e
                raise e, ERROR_MESSAGE_INVALID_HEADERS
              end
              raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if k.empty? || v.empty?

              { name: k, value: v }
            end
          end
        end
      end
    end
  end
end
